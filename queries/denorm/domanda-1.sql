
/* QUERY 1 - DENORM */

/* NUMBER OF EXAMS, ENROLLMENTS AND AVERAGE OF ENROLLMETS BY CDS, AD AND YEAR */
WITH cds_ad_appelli_iscrizioni AS (

	SELECT t2.*, t3.numero_iscrizioni, ROUND(CAST(t3.numero_iscrizioni AS REAL) / CAST(t2.numero_appelli AS REAL), 3) AS media_iscrizioni_appello
	FROM (
		
		/* NUMBER OF EXAMS BY CDS, AD AND YEAR */
		SELECT t1.cdscod, t1.adcod, STRFTIME('%Y', t1.dtappello) AS anno,
			COUNT(*) AS numero_appelli
		FROM (
			SELECT DISTINCT bos_denormalizzato.CdSCod, bos_denormalizzato.adcod, bos_denormalizzato.DtAppello
			FROM bos_denormalizzato
		) AS t1
		GROUP BY t1.cdscod, t1.adcod, STRFTIME('%Y', t1.dtappello)

	) AS t2
	INNER JOIN (
		
		/* NUMBER OF ENROLLMENTS BY CDS, AD AND YEAR */
		SELECT bos_denormalizzato.cdscod, bos_denormalizzato.AdCod, STRFTIME('%Y', bos_denormalizzato.dtappello) AS anno, 
			COUNT(*) AS numero_iscrizioni
		FROM bos_denormalizzato
		GROUP BY bos_denormalizzato.cdscod, bos_denormalizzato.AdCod, STRFTIME('%Y', bos_denormalizzato.dtappello)

	) AS t3 ON t3.cdscod = t2.cdscod
		AND t3.adcod = t2.adcod	
		AND t3.anno = t2.anno

)

/* NUMBER OF EXAMS, ENROLLMENTS AND AVERAGE OF ENROLLMETS BY CDS AND YEAR */
SELECT cdscod, anno, SUM(numero_appelli) AS numero_appelli, SUM(numero_iscrizioni) AS numero_iscrizioni, 
	ROUND(CAST(SUM(numero_iscrizioni) AS REAL) / CAST(SUM(numero_appelli) AS REAL), 3) AS media_iscrizioni_appello
FROM cds_ad_appelli_iscrizioni	
GROUP BY cdscod, anno;
		
	
