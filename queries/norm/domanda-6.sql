
/* DOMANDA 6 - NORM */

/* VIEW: STUDENTS STATS AND TRIAL/ERROR INDEX FOR EACH AD */
DROP VIEW IF EXISTS query6_stats_stud_ad;
CREATE VIEW IF NOT EXISTS query6_stats_stud_ad AS 

	SELECT *, CAST(t1.n_insufficienze * 1.5 + t1.n_ritiri * 1 + t1.n_assenze * 0.5 AS REAL) AS trial_error
	FROM (

		/* NUMBER OF INSUFFICIENT, RETIRED AND ABSENST FOR EACH STUDENT IN AN AD */
		SELECT appelli.cdscod, appelli.adcod, iscrizioni.studente, 
			SUM(CASE WHEN iscrizioni.Insufficienza = 1 THEN 1 ELSE 0 END) AS n_insufficienze,
			SUM(CASE WHEN iscrizioni.Ritiro = 1 THEN 1 ELSE 0 END) AS n_ritiri,
			SUM(CASE WHEN iscrizioni.Assenza = 1 THEN 1 ELSE 0 END) AS n_assenze
		FROM iscrizioni
		INNER JOIN appelli ON iscrizioni.appcod = appelli.appcod
		WHERE appelli.appello_chiuso = 1
		GROUP BY appelli.cdscod, appelli.adcod, iscrizioni.studente
		
	) AS t1;
	

/* VIEW: TRIAL&ERROR INDEX FOR AD */
DROP VIEW IF EXISTS query6_trial_error_ad;
CREATE VIEW IF NOT EXISTS query6_trial_error_ad AS

	SELECT query6_stats_stud_ad.cdscod, query6_stats_stud_ad.adcod, COUNT(*) AS n_studenti,
		ROUND(AVG(query6_stats_stud_ad.trial_error), 3) AS trial_error,
		DENSE_RANK() OVER( PARTITION BY query6_stats_stud_ad.cdscod ORDER BY ROUND(AVG(query6_stats_stud_ad.trial_error), 3) DESC) AS rank_trial_error
	FROM query6_stats_stud_ad
	GROUP BY query6_stats_stud_ad.cdscod, query6_stats_stud_ad.adcod
	HAVING n_studenti > 2;


/* VIEW: TRIAL&ERROR INDEX FOR CDS */
DROP VIEW IF EXISTS query6_trial_error_cdscod;
CREATE VIEW IF NOT EXISTS query6_trial_error_cdscod AS

	SELECT query6_trial_error_ad.cdscod, 
		ROUND(AVG(query6_trial_error_ad.trial_error), 3) AS trial_error,
		DENSE_RANK() OVER( ORDER BY ROUND(AVG(query6_trial_error_ad.trial_error), 3) DESC) AS rank_trial_error
	FROM query6_trial_error_ad
	GROUP BY query6_trial_error_ad.cdscod;
	
	
/* VIEW: TOP-3 TRIAL&ERROR CDS AND AD */
DROP VIEW IF EXISTS query6_top3_cds_ad;
CREATE VIEW IF NOT EXISTS query6_top3_cds_ad AS
	
	SELECT query6_trial_error_ad.cdscod, query6_trial_error_ad.adcod, query6_trial_error_ad.trial_error, query6_trial_error_ad.rank_trial_error
	FROM query6_trial_error_ad
	WHERE query6_trial_error_ad.rank_trial_error <= 3;


/* VIEW: TOP-3 TRIAL&ERROR CDS */
DROP VIEW IF EXISTS query6_top3_cds;
CREATE VIEW IF NOT EXISTS query6_top3_cds AS
	
	SELECT query6_trial_error_cdscod.cdscod, query6_trial_error_cdscod.trial_error, query6_trial_error_cdscod.rank_trial_error
	FROM query6_trial_error_cdscod
	WHERE query6_trial_error_cdscod.rank_trial_error <= 3;

	