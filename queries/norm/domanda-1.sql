
/* QUERY 1 - NORM */

/* VIEW: NUMBER OF ENROLLED STUDENTS FOR EACH EXAM */
DROP VIEW IF EXISTS query1_appelli_iscritti;
CREATE VIEW IF NOT EXISTS query1_appelli_iscritti AS
	
	/* AGGREGATION OF EXAMS WITH THE SAME CDS, ADCOD AND DATE, SUMMING THE NUMBER OF ENROLLMENTS */
	SELECT stats_appelli.cdscod, stats_appelli.adcod, stats_appelli.dtappello, 
		SUM(stats_appelli.numero_iscritti) AS numero_iscritti
	FROM stats_appelli
	GROUP BY stats_appelli.cdscod, stats_appelli.adcod, stats_appelli.dtappello
	ORDER BY cdscod, adcod, dtappello ASC;

	
/* VIEW: NUMBER OF EXAMS, ENROLLMENTS, AVERAGE OF ENROLLMETS PER CDS (GROUPING PER YEAR) */
DROP VIEW IF EXISTS query1_cds_appelli_iscrizioni;
CREATE VIEW IF NOT EXISTS query1_cds_appelli_iscrizioni AS

	/* COMPUTING THE STATS */
	SELECT query1_appelli_iscritti.cdscod, STRFTIME('%Y', query1_appelli_iscritti.dtappello) AS anno, 
		COUNT(*) AS numero_appelli, SUM(query1_appelli_iscritti.numero_iscritti) AS numero_iscrizioni,
		ROUND(CAST(SUM(query1_appelli_iscritti.numero_iscritti) AS REAL) / CAST(COUNT(*) AS REAL), 3) AS media_iscrizioni_appello
	FROM query1_appelli_iscritti
	GROUP BY query1_appelli_iscritti.cdscod, STRFTIME('%Y', query1_appelli_iscritti.dtappello);
	
	
/* VIEW: NUMBER OF EXAMS, ENROLLMENTS, AVERAGE OF ENROLLMETS PER CDS AND AD (GROUPING PER YEAR) */
DROP VIEW IF EXISTS query1_cds_ad_appelli_iscrizioni;
CREATE VIEW IF NOT EXISTS query1_cds_ad_appelli_iscrizioni AS

	/* COMPUTING THE STATS */
	SELECT query1_appelli_iscritti.cdscod, query1_appelli_iscritti.adcod, STRFTIME('%Y', query1_appelli_iscritti.dtappello) AS anno, 
		COUNT(*) AS numero_appelli, SUM(query1_appelli_iscritti.numero_iscritti) AS numero_iscrizioni,
		ROUND(CAST(SUM(query1_appelli_iscritti.numero_iscritti) AS REAL) / CAST(COUNT(*) AS REAL), 3) AS media_iscrizioni_appello
	FROM query1_appelli_iscritti
	GROUP BY query1_appelli_iscritti.cdscod, query1_appelli_iscritti.adcod, STRFTIME('%Y', query1_appelli_iscritti.dtappello);

	