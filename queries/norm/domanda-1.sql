
/* QUERY 1 - NORM */
	
/* VIEW: NUMBER OF EXAMS, ENROLLMENTS, AVERAGE OF ENROLLMETS PER CDS (GROUPING PER YEAR) */
DROP VIEW IF EXISTS query1_cds_appelli_iscrizioni;
CREATE VIEW IF NOT EXISTS query1_cds_appelli_iscrizioni AS

	/* COMPUTING THE STATS */
	SELECT stats_appelli_agg.cdscod, STRFTIME('%Y', stats_appelli_agg.dtappello) AS anno, 
		COUNT(*) AS numero_appelli, SUM(stats_appelli_agg.numero_iscritti) AS numero_iscrizioni,
		ROUND(CAST(SUM(stats_appelli_agg.numero_iscritti) AS REAL) / CAST(COUNT(*) AS REAL), 3) AS media_iscrizioni_appello
	FROM (
			
		/* AGGREGATION OF EXAMS WITH THE SAME CDS, ADCOD AND DATE (BUT DIFFERENT TEACHERS), SUMMING THE NUMBER OF ENROLLMENTS */
		SELECT stats_appelli.cdscod, stats_appelli.adcod, stats_appelli.dtappello, 
			SUM(stats_appelli.numero_iscritti) AS numero_iscritti
		FROM stats_appelli
		GROUP BY stats_appelli.cdscod, stats_appelli.adcod, stats_appelli.dtappello
			
	) AS stats_appelli_agg
	GROUP BY stats_appelli_agg.cdscod, STRFTIME('%Y', stats_appelli_agg.dtappello);
	
	
/* VIEW: NUMBER OF EXAMS, ENROLLMENTS, AVERAGE OF ENROLLMETS PER CDS AND AD (GROUPING PER YEAR) */
DROP VIEW IF EXISTS query1_cds_ad_appelli_iscrizioni;
CREATE VIEW IF NOT EXISTS query1_cds_ad_appelli_iscrizioni AS

	/* COMPUTING THE STATS */
	SELECT stats_appelli_agg.cdscod, stats_appelli_agg.adcod, STRFTIME('%Y', stats_appelli_agg.dtappello) AS anno, 
		COUNT(*) AS numero_appelli, SUM(stats_appelli_agg.numero_iscritti) AS numero_iscrizioni,
		ROUND(CAST(SUM(stats_appelli_agg.numero_iscritti) AS REAL) / CAST(COUNT(*) AS REAL), 3) AS media_iscrizioni_appello
	FROM (
			
		/* AGGREGATION OF EXAMS WITH THE SAME CDS, ADCOD AND DATE (BUT DIFFERENT TEACHERS), SUMMING THE NUMBER OF ENROLLMENTS */
		SELECT stats_appelli.cdscod, stats_appelli.adcod, stats_appelli.dtappello, 
			SUM(stats_appelli.numero_iscritti) AS numero_iscritti
		FROM stats_appelli
		GROUP BY stats_appelli.cdscod, stats_appelli.adcod, stats_appelli.dtappello
			
	) AS stats_appelli_agg
	GROUP BY stats_appelli_agg.cdscod, stats_appelli_agg.adcod, STRFTIME('%Y', stats_appelli_agg.dtappello);

	
/* VIEW: NUMBER OF ENROLLED STUDENTS FOR EACH EXAM */
DROP VIEW IF EXISTS query1_appelli_iscritti;
CREATE VIEW IF NOT EXISTS query1_appelli_iscritti AS

	SELECT stats_appelli_agg.cdscod, stats_appelli_agg.adcod, stats_appelli_agg.dtappello, 
		SUM(stats_appelli_agg.numero_iscritti) AS numero_iscritti
	FROM (
			
		/* AGGREGATION OF EXAMS WITH THE SAME CDS, ADCOD AND DATE (BUT DIFFERENT TEACHERS), SUMMING THE NUMBER OF ENROLLMENTS */
		SELECT stats_appelli.cdscod, stats_appelli.adcod, stats_appelli.dtappello, 
			SUM(stats_appelli.numero_iscritti) AS numero_iscritti
		FROM stats_appelli
		GROUP BY stats_appelli.cdscod, stats_appelli.adcod, stats_appelli.dtappello
			
	) AS stats_appelli_agg
	GROUP BY stats_appelli_agg.cdscod, stats_appelli_agg.adcod, stats_appelli_agg.dtappello
	ORDER BY cdscod, adcod, dtappello ASC;

