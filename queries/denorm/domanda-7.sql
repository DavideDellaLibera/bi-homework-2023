
/* DOMANDA 7 - DENORM */

/* PASSED AD OF STUDENTS */
WITH ad_passed_students AS (

	SELECT DISTINCT cdscod, adcod, studente
	FROM bos_denormalizzato	
	WHERE Superamento = 1
	
),

/* COMPUTE FAST AND FURIOUS INDEX */
fast_and_furious_index AS (

	SELECT t3.*, ROUND(t3.mesi_att_norm * 0.25 + t3.tasso_successo * 0.25 + t3.voto_medio_norm * 0.25 + t3.n_esami_superati_norm * 0.25, 3) AS fast_and_furious
	FROM (

		SELECT params_fast.cdscod, params_fast.studente,
			params_fast.mesi_att, 1 - CAST(((params_fast.mesi_att - 1) / 12.0) AS REAL) AS mesi_att_norm,
			params_furious.tasso_successo,
			params_furious.voto_medio, params_furious.voto_medio / 30 AS voto_medio_norm,
			params_furious.n_esami_superati, CAST(params_furious.n_esami_superati AS REAL) / MAX(params_furious.n_esami_superati) OVER( PARTITION BY params_furious.cdscod ORDER BY params_furious.n_esami_superati DESC ) AS n_esami_superati_norm
				
		FROM (

			/* FAST PARAMETER: PERIOD OF ACTIVITY GIVEN BY THE DIFFERENCE BETWEEN FIRST AND LAST EXAM TAKEN BY EACH STUDENT */
			SELECT cdscod, studente, 
				CAST(ROUND((JULIANDAY(DATE(MAX(dtappello), 'start of month')) - JULIANDAY(DATE(MIN(dtappello), 'start of month'))) / 30) + 1 AS INTEGER) AS mesi_att
			FROM bos_denormalizzato
			WHERE appello_chiuso = 1
			GROUP BY cdscod, studente
			
		) AS params_fast
		INNER JOIN (

			/* FURIOUS PARMETERS: NUMBER OF PASSED EXAMS, AVERAGE GRADE AND SUCCESS RATIO  FOR EACH STUDENT*/
			SELECT t1.cdscod, t1.studente, t1.n_esami_superati, 
				(CASE WHEN t1.voto_medio IS NULL THEN 0 ELSE t1.voto_medio END) AS voto_medio,
				(CAST(t1.n_esami_superati AS REAL) / CAST(n_iscrizioni AS REAL)) AS tasso_successo
			FROM (

				/* NUMBER OF ENROLLMENTS, PASSED EXAMS AND AVERAGE GRADE FOR EACH STUDENT */
				SELECT cdscod, studente, COUNT(*) AS n_iscrizioni, 
					SUM(CASE WHEN Superamento = 1 THEN 1 ELSE 0 END) AS n_esami_superati, AVG(voto) AS voto_medio
				FROM bos_denormalizzato
				WHERE appello_chiuso = 1
				GROUP BY cdscod, studente

			) AS t1
			
		) AS params_furious ON params_furious.cdscod = params_fast.cdscod
			AND params_furious.studente = params_fast.studente
			
	) AS t3
	
),

/* TRIAL AND ERROR INDEX FOR EACH AD */
trial_error_index_ad AS (
	
	SELECT t2.cdscod, t2.adcod, AVG(trial_error) AS avg_trial_error_index
	FROM (
	
		SELECT cdscod, adcod, studente, (CAST(t1.n_insufficienze * 1.5 + t1.n_ritiri * 1 + t1.n_assenze * 0.5 AS REAL)) AS trial_error
		FROM (

			SELECT cdscod, adcod, studente,
				SUM(CASE WHEN Insufficienza = 1 THEN 1 ELSE 0 END) AS n_insufficienze,
				SUM(CASE WHEN Ritiro = 1 THEN 1 ELSE 0 END) AS n_ritiri,
				SUM(CASE WHEN Assenza = 1 THEN 1 ELSE 0 END) AS n_assenze
			FROM bos_denormalizzato
			WHERE appello_chiuso = 1
			GROUP BY cdscod, adcod, studente
			
		) AS t1
		
	) AS t2
	GROUP BY t2.cdscod, t2.adcod
	
),

/* DIFFICULTY STATS FOR EACH EXAM (CLOSED) */
app_difficulty AS (

	SELECT t1.*, 
		CAST(t1.numero_promossi AS REAL) / CAST(t1.numero_iscritti AS REAL) AS tasso_superamento,
		voto_mediano_appello.voto_mediano,
		
		CASE WHEN t1.voto_medio IS NOT NULL AND voto_mediano_appello.voto_mediano IS NULL
			THEN ROUND((t1.voto_medio + ROUND((CAST(t1.numero_promossi AS REAL) / CAST(t1.numero_iscritti AS REAL)) / (0.498/16) + 1, 1)) / 2, 3)
			ELSE CASE WHEN t1.voto_medio IS NULL
				THEN 0 ELSE ROUND((t1.voto_medio + voto_mediano_appello.voto_mediano) / 2, 3)
			END
		END AS voto_agg

	FROM (

		SELECT cdscod, adcod, docente, dtappello, 
			COUNT(*) AS numero_iscritti, AVG(voto) AS voto_medio,
			SUM(CASE WHEN superamento = 1 THEN 1 ELSE 0 END) AS numero_promossi
		FROM bos_denormalizzato
		WHERE appello_chiuso = 1
		GROUP BY cdscod, adcod, docente, dtappello
		
	) AS t1
	INNER JOIN (
		
		SELECT ranking.cdscod, ranking.adcod, ranking.docente, ranking.dtappello, 
			AVG(ranking.voto) AS voto_mediano
		FROM (
			SELECT cdscod, adcod, docente, dtappello, voto,
				ROW_NUMBER() OVER (PARTITION BY cdscod, adcod, docente, dtappello ORDER BY Voto ASC) AS rank_voto,
				COUNT(*) OVER (PARTITION BY cdscod, adcod, docente, dtappello) AS numero_iscritti
			FROM bos_denormalizzato
			WHERE appello_chiuso = 1
		) AS ranking
		WHERE rank_voto IN ((ranking.numero_iscritti + 1) / 2, (ranking.numero_iscritti + 2) / 2)
		GROUP BY ranking.cdscod, ranking.adcod, ranking.docente, ranking.dtappello
		
	) AS voto_mediano_appello ON voto_mediano_appello.cdscod = t1.cdscod
		AND voto_mediano_appello.cdscod = t1.cdscod
		AND voto_mediano_appello.adcod = t1.adcod
		AND voto_mediano_appello.docente = t1.docente
		AND voto_mediano_appello.dtappello = t1.dtappello
		
),

/* AVERAGE NUMBER OF TRIES OF EACH AD */
media_tentativi_stud_ad AS (

	SELECT t1.cdscod, t1.adcod, ROUND(AVG(t1.numero_tentativi), 3) AS media_tentativi
	FROM (
		SELECT studente, cdscod, adcod, COUNT(*) AS numero_tentativi
		FROM bos_denormalizzato
		WHERE appello_chiuso = 1
		GROUP BY studente, cdscod, adcod
	) AS t1
	GROUP BY t1.cdscod, t1.adcod

),

/* MEDIAN SUCCESS RATIO FOR EACH AD */
ts_mediano_ad AS (
	
	SELECT ranking.cdscod, ranking.adcod, ROUND(AVG(ranking.tasso_superamento), 3) AS ts_mediano
	FROM (
		SELECT *,
			ROW_NUMBER() OVER (PARTITION BY app_difficulty.cdscod, app_difficulty.adcod ORDER BY app_difficulty.tasso_superamento ASC) AS rank_ts,
			COUNT(*) OVER (PARTITION BY app_difficulty.cdscod, app_difficulty.adcod) AS numero_appelli
		FROM app_difficulty
	) AS ranking
	WHERE rank_ts IN ((ranking.numero_appelli + 1) / 2, (ranking.numero_appelli + 2) / 2)
	GROUP BY ranking.cdscod, ranking.adcod

),

/* MEDIAN AGGREGATED GRADE FOR EACH AD */
voto_agg_mediano_ad AS (
	
	SELECT ranking.cdscod, ranking.adcod, ROUND(AVG(ranking.voto_agg), 3) AS voto_agg_mediano
	FROM (
		SELECT *,
			ROW_NUMBER() OVER(
				PARTITION BY app_difficulty.cdscod, app_difficulty.adcod 
				ORDER BY app_difficulty.voto_agg ASC
			) AS rank_appello,
			COUNT(*) OVER( PARTITION BY app_difficulty.cdscod, app_difficulty.adcod ) AS numero_appelli
		FROM app_difficulty
	) AS ranking
	WHERE rank_appello IN ((ranking.numero_appelli + 1) / 2, (ranking.numero_appelli + 2) / 2)
	GROUP BY ranking.cdscod, ranking.adcod
	
),

/* NUMBER OF EXAMS FOR EACH AD (AT LEAST 2 EXAMS TO BE CONSIDERED) */
numero_appelli_ad AS (

	SELECT app_difficulty.cdscod, app_difficulty.adcod, COUNT(*) AS numero_appelli
	FROM app_difficulty
	GROUP BY app_difficulty.cdscod, app_difficulty.adcod
	HAVING numero_appelli > 1

),

/* RANKING ALGORITHM */
rank_pesato_ad AS (

	SELECT rankings.cdscod, rankings.adcod,
		rankings.rank_ts * 0.4 + rankings.rank_voto_agg * 0.3 + rankings.rank_media_tentativi * 0.3 AS rank_pesato
	FROM (

		SELECT t1.cdscod, t1.adcod, 
			
			DENSE_RANK() OVER( 
				PARTITION BY t1.cdscod
				ORDER BY t1.ts_mediano ASC
			) AS rank_ts,
				
			DENSE_RANK() OVER( 
				PARTITION BY t1.cdscod
				ORDER BY t1.voto_agg_mediano ASC
			) AS rank_voto_agg,
				
			DENSE_RANK() OVER( 
				PARTITION BY t1.cdscod
				ORDER BY t1.media_tentativi DESC
			) AS rank_media_tentativi
				
		FROM (

			SELECT media_tentativi_stud_ad.*, ts_mediano_ad.ts_mediano, voto_agg_mediano_ad.voto_agg_mediano, numero_appelli_ad.numero_appelli
			FROM media_tentativi_stud_ad
			INNER JOIN ts_mediano_ad ON ts_mediano_ad.cdscod = media_tentativi_stud_ad.cdscod
				AND ts_mediano_ad.adcod = media_tentativi_stud_ad.adcod
			INNER JOIN voto_agg_mediano_ad ON voto_agg_mediano_ad.cdscod = media_tentativi_stud_ad.cdscod
				AND voto_agg_mediano_ad.adcod = media_tentativi_stud_ad.adcod
			INNER JOIN numero_appelli_ad ON numero_appelli_ad.cdscod = media_tentativi_stud_ad.cdscod
				AND numero_appelli_ad.adcod = media_tentativi_stud_ad.adcod
				
		) AS t1
		
	) AS rankings
	
),

/* NUMBER OF AWARDS FOR CDS */
numero_premi_cds AS (
	
	SELECT numero_premi_cds.cdscod, CASE WHEN numero_premi = 0 THEN 1 ELSE numero_premi END AS numero_premi
	FROM (	

		SELECT general_info_cds.cdscod, 
			CAST(CAST(general_info_cds.numero_studenti AS REAL) / CAST((SELECT SUM(numero_studenti) FROM general_info_cds) AS REAL) * 100 AS INTEGER) AS numero_premi
		FROM general_info_cds
		
	) AS numero_premi_cds

)


SELECT *
FROM (

	SELECT *, ROW_NUMBER() OVER (PARTITION BY t3.cdscod ORDER BY t3.gold_mortarboard_score DESC) AS position
	FROM (

		SELECT t2.cdscod, t2.studente, ROUND(t2.avg_trial_error_index * 0.25 + t2.avg_difficulty_index * 0.25 + t2.fast_and_furious * 0.5, 3) AS gold_mortarboard_score, numero_premi_cds.numero_premi
		FROM (	

			SELECT t1.cdscod, t1.studente, t1.fast_and_furious, ROUND(AVG(t1.trial_error_index_norm), 3) AS avg_trial_error_index, ROUND(AVG(t1.difficulty_index_norm), 3) AS avg_difficulty_index
			FROM (

				SELECT ad_passed_students.*, fast_and_furious_index.n_esami_superati, fast_and_furious_index.fast_and_furious,
					(trial_error_index_ad.avg_trial_error_index - MIN(trial_error_index_ad.avg_trial_error_index) OVER (PARTITION BY trial_error_index_ad.cdscod)) / (MAX(trial_error_index_ad.avg_trial_error_index) OVER (PARTITION BY trial_error_index_ad.cdscod) - MIN(trial_error_index_ad.avg_trial_error_index) OVER (PARTITION BY trial_error_index_ad.cdscod)) AS trial_error_index_norm,
					 1 - ((rank_pesato_ad.rank_pesato - MIN(rank_pesato_ad.rank_pesato) OVER (PARTITION BY rank_pesato_ad.cdscod)) / (MAX(rank_pesato_ad.rank_pesato) OVER (PARTITION BY rank_pesato_ad.cdscod) - MIN(rank_pesato_ad.rank_pesato) OVER (PARTITION BY rank_pesato_ad.cdscod))) AS difficulty_index_norm
				FROM ad_passed_students
				LEFT JOIN rank_pesato_ad ON rank_pesato_ad.cdscod = ad_passed_students.cdscod
					AND rank_pesato_ad.adcod = ad_passed_students.adcod
				LEFT JOIN trial_error_index_ad ON trial_error_index_ad.cdscod = ad_passed_students.cdscod
					AND trial_error_index_ad.adcod = ad_passed_students.adcod
				LEFT JOIN fast_and_furious_index ON fast_and_furious_index.cdscod = ad_passed_students.cdscod
					AND fast_and_furious_index.studente = ad_passed_students.studente
				WHERE fast_and_furious_index.n_esami_superati > 5
					AND rank_pesato_ad.rank_pesato IS NOT NULL
					
			) AS t1
			GROUP BY t1.cdscod, t1.studente

		) AS t2
		INNER JOIN numero_premi_cds ON numero_premi_cds.cdscod = t2.cdscod
		
	) AS t3
	
) AS t4
WHERE t4.position <= t4.numero_premi;
	
