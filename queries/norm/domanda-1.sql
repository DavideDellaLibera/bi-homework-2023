
/* QUERY 1 - NORM */

/* VIEW: NUMBER OF STUDENTS ENROLLED FOR EACH EXAM */
DROP VIEW IF EXISTS stats_appelli_agg;
CREATE VIEW IF NOT EXISTS stats_appelli_agg AS

	/* NUMBER OF ENROLLED STUDENTS AT EACH EXAM */
	SELECT stats_appelli.cdscod, stats_appelli.adcod, stats_appelli.dtappello, 
		SUM(stats_appelli.numero_iscritti) AS numero_iscritti
	FROM stats_appelli
	GROUP BY stats_appelli.cdscod, stats_appelli.adcod, stats_appelli.dtappello
	ORDER BY cdscod, adcod, dtappello ASC;

	
/* VIEW: NUMBER OF EXAMS, ENROLLMENTS, AVERAGE OF ENROLLMETS PER CDS */
DROP VIEW IF EXISTS query1_cds_appelli_iscrizioni;
CREATE VIEW IF NOT EXISTS query1_cds_appelli_iscrizioni AS

	SELECT stats_appelli_agg.cdscod, STRFTIME('%Y', stats_appelli_agg.dtappello) AS anno, 
		COUNT(*) AS numero_appelli, SUM(stats_appelli_agg.numero_iscritti) AS numero_iscrizioni,
		ROUND(CAST(SUM(stats_appelli_agg.numero_iscritti) AS REAL) / CAST(COUNT(*) AS REAL), 3) AS media_iscrizioni_appello
	FROM stats_appelli_agg 
	GROUP BY stats_appelli_agg.cdscod, STRFTIME('%Y', stats_appelli_agg.dtappello);
	
	
/* VIEW: NUMBER OF EXAMS, ENROLLMENTS, AVERAGE OF ENROLLMETS PER CDS AND AD */
DROP VIEW IF EXISTS query1_cds_ad_appelli_iscrizioni;
CREATE VIEW IF NOT EXISTS query1_cds_ad_appelli_iscrizioni AS

	SELECT stats_appelli_agg.cdscod, stats_appelli_agg.adcod, STRFTIME('%Y', stats_appelli_agg.dtappello) AS anno, 
		COUNT(*) AS numero_appelli, SUM(stats_appelli_agg.numero_iscritti) AS numero_iscrizioni,
		ROUND(CAST(SUM(stats_appelli_agg.numero_iscritti) AS REAL) / CAST(COUNT(*) AS REAL), 3) AS media_iscrizioni_appello
	FROM stats_appelli_agg
	GROUP BY stats_appelli_agg.cdscod, stats_appelli_agg.adcod, STRFTIME('%Y', stats_appelli_agg.dtappello);
