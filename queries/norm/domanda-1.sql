
/* QUERY 1 - NORM */
	
/* VIEW: NUMBER OF EXAMS, ENROLLMENTS, AVERAGE OF ENROLLMETS PER CDS */
DROP VIEW IF EXISTS query1_cds_appelli_iscrizioni;
CREATE VIEW IF NOT EXISTS query1_cds_appelli_iscrizioni AS

	SELECT stats_appelli_agg.cdscod, STRFTIME('%Y', stats_appelli_agg.dtappello) AS anno, 
		COUNT(*) AS numero_appelli, SUM(stats_appelli_agg.numero_iscritti) AS numero_iscrizioni,
		ROUND(CAST(SUM(stats_appelli_agg.numero_iscritti) AS REAL) / CAST(COUNT(*) AS REAL), 3) AS media_iscrizioni_appello
	FROM (
			
		/* STATISTICHE APPELLI CON AGGREGAZIONE STESSI CDS, ADCOD E DATA */
		SELECT stats_appelli.cdscod, stats_appelli.adcod, stats_appelli.dtappello, 
			SUM(stats_appelli.numero_iscritti) AS numero_iscritti
		FROM stats_appelli
		GROUP BY stats_appelli.cdscod, stats_appelli.adcod, stats_appelli.dtappello
			
	) AS stats_appelli_agg
	GROUP BY stats_appelli_agg.cdscod, STRFTIME('%Y', stats_appelli_agg.dtappello);
	
	
/* VIEW: NUMBER OF EXAMS, ENROLLMENTS, AVERAGE OF ENROLLMETS PER CDS AND AD */
DROP VIEW IF EXISTS query1_cds_ad_appelli_iscrizioni;
CREATE VIEW IF NOT EXISTS query1_cds_ad_appelli_iscrizioni AS

	SELECT stats_appelli_agg.cdscod, stats_appelli_agg.adcod, STRFTIME('%Y', stats_appelli_agg.dtappello) AS anno, 
		COUNT(*) AS numero_appelli, SUM(stats_appelli_agg.numero_iscritti) AS numero_iscrizioni,
		ROUND(CAST(SUM(stats_appelli_agg.numero_iscritti) AS REAL) / CAST(COUNT(*) AS REAL), 3) AS media_iscrizioni_appello
	FROM (
			
		/* STATISTICHE APPELLI CON AGGREGAZIONE STESSI CDS, ADCOD E DATA */
		SELECT stats_appelli.cdscod, stats_appelli.adcod, stats_appelli.dtappello, 
			SUM(stats_appelli.numero_iscritti) AS numero_iscritti
		FROM stats_appelli
		GROUP BY stats_appelli.cdscod, stats_appelli.adcod, stats_appelli.dtappello
			
	) AS stats_appelli_agg
	GROUP BY stats_appelli_agg.cdscod, stats_appelli_agg.adcod, STRFTIME('%Y', stats_appelli_agg.dtappello);

	
/* VIEW: NUMERO DI ISCRITTI PER CIASCUN APPELLO */
DROP VIEW IF EXISTS query1_appelli_iscritti;
CREATE VIEW IF NOT EXISTS query1_appelli_iscritti AS

	SELECT stats_appelli_agg.cdscod, stats_appelli_agg.adcod, stats_appelli_agg.dtappello, 
		SUM(stats_appelli_agg.numero_iscritti) AS numero_iscritti
	FROM (
			
		/* STATISTICHE APPELLI CON AGGREGAZIONE STESSI CDS, ADCOD E DATA */
		SELECT stats_appelli.cdscod, stats_appelli.adcod, stats_appelli.dtappello, 
			SUM(stats_appelli.numero_iscritti) AS numero_iscritti
		FROM stats_appelli
		GROUP BY stats_appelli.cdscod, stats_appelli.adcod, stats_appelli.dtappello
			
	) AS stats_appelli_agg
	GROUP BY stats_appelli_agg.cdscod, stats_appelli_agg.adcod, stats_appelli_agg.dtappello
	ORDER BY cdscod, adcod, dtappello ASC;

