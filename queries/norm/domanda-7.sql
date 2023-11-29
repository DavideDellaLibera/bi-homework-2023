
/* DOMANDA 7 - NORM */

/* VIEW: GOLD MORTARBOARD SCORE */
DROP VIEW IF EXISTS query7_gold_mortarboard_scores;
CREATE VIEW IF NOT EXISTS query7_gold_mortarboard_scores AS

	/* COMPUTE THE GOLD MORTARBOARD SCORE WEIGHTING THE THREE NORMALIZED PARAMETERS  */
	SELECT ad_difficulty_params.*, fast_and_furious_index.fast_and_furious AS fast_and_furios_index,
		ROUND(ad_difficulty_params.avg_trial_error_index * 0.25 + ad_difficulty_params.avg_difficulty_index * 0.25 + fast_and_furious_index.fast_and_furious * 0.5, 3) AS gold_mortarboard_score
	FROM (

		/* FIRST PARAMETER: AVERAGE OF TRIAL AND ERROR INDECES (NORMALIZED)
		   SECOND PARAMETER: AVERAGE OF DIFFICULTY INDECES (NORMALIZED) */
		SELECT students_passed_exam.cdscod, students_passed_exam.studente,
			ROUND(AVG(difficulty_index_ad.trial_error_index_norm), 3) AS avg_trial_error_index, 
			ROUND(AVG(difficulty_index_ad.difficulty_index_norm), 3) AS avg_difficulty_index
		FROM (
			
			/* AD PASSED BY STUDENTS */
			SELECT DISTINCT appelli.cdscod, appelli.adcod, iscrizioni.studente
			FROM iscrizioni
			INNER JOIN appelli ON appelli.appcod = iscrizioni.appcod	
			WHERE iscrizioni.Superamento = 1
	
		) AS students_passed_exam
		LEFT JOIN (

			/* DIFFICULTY PARAMS FOR EACH AD */
			SELECT query6_trial_error_ad.cdscod, query6_trial_error_ad.adcod, 
				(query6_trial_error_ad.trial_error - MIN(query6_trial_error_ad.trial_error) OVER (PARTITION BY query6_trial_error_ad.cdscod)) / (MAX(query6_trial_error_ad.trial_error) OVER (PARTITION BY query6_trial_error_ad.cdscod) - MIN(query6_trial_error_ad.trial_error) OVER (PARTITION BY query6_trial_error_ad.cdscod)) AS trial_error_index_norm,
				1 - ((query2_rankings.rank_pesato - MIN(query2_rankings.rank_pesato) OVER (PARTITION BY query6_trial_error_ad.cdscod)) / (MAX(query2_rankings.rank_pesato) OVER (PARTITION BY query6_trial_error_ad.cdscod) - MIN(query2_rankings.rank_pesato) OVER (PARTITION BY query6_trial_error_ad.cdscod))) AS difficulty_index_norm
			FROM query6_trial_error_ad
			INNER JOIN query2_rankings ON query2_rankings.cdscod = query6_trial_error_ad.cdscod
				AND query2_rankings.adcod = query6_trial_error_ad.adcod
				
		) AS difficulty_index_ad ON difficulty_index_ad.cdscod = students_passed_exam.cdscod
			AND difficulty_index_ad.adcod = students_passed_exam.adcod
		GROUP BY students_passed_exam.cdscod, students_passed_exam.studente
		
	) AS ad_difficulty_params
	LEFT JOIN (

		/* THIRD PARAMETER: FAST AND FURIOUS INDEX */
		SELECT cdscod, studente, fast_and_furious, n_esami_superati
		FROM query5_fast_and_furious
		
	) AS fast_and_furious_index ON fast_and_furious_index.cdscod = ad_difficulty_params.cdscod
		AND fast_and_furious_index.studente = ad_difficulty_params.studente
	WHERE fast_and_furious_index.n_esami_superati > 5;
	

/* VIEW: NUMBER OF AWARDS FOR EACH CDS (FAIRNESS: PROPORTIONAL TO THE NUMBER OF STUDENT IN THE CDS) */
DROP VIEW IF EXISTS query7_numero_premi_cds;
CREATE VIEW IF NOT EXISTS query7_numero_premi_cds AS
	
	SELECT numero_premi_cds.cdscod, CASE WHEN numero_premi = 0 THEN 1 ELSE numero_premi END AS numero_premi
	FROM (	

		SELECT general_info_cds.cdscod, 
			CAST(CAST(general_info_cds.numero_studenti AS REAL) / CAST((SELECT SUM(numero_studenti) FROM general_info_cds) AS REAL) * 100 AS INTEGER) AS numero_premi
		FROM general_info_cds
		
	) AS numero_premi_cds;


/* VIEW: STUDENTS FOR GOLD MORTARBOARD */	
DROP VIEW IF EXISTS query7_gold_mortarboard_students;
CREATE VIEW IF NOT EXISTS query7_gold_mortarboard_students AS

	SELECT rankings.cdscod, rankings.studente,
		rankings.avg_trial_error_index, rankings.avg_difficulty_index, rankings.fast_and_furios_index, 
		rankings.gold_mortarboard_score, rankings.position
	FROM (	

		/* RANKINGS */
		SELECT *, 
			ROW_NUMBER() OVER (PARTITION BY query7_gold_mortarboard_scores.cdscod ORDER BY query7_gold_mortarboard_scores.gold_mortarboard_score DESC) AS position
		FROM query7_gold_mortarboard_scores
		INNER JOIN query7_numero_premi_cds ON query7_numero_premi_cds.cdscod = query7_gold_mortarboard_scores.cdscod
		
	) AS rankings
	WHERE rankings.position <= rankings.numero_premi;

