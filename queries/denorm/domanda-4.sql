
/* DOMANDA 4 - DENORM */

/* NUMBER OF EXAMS PER AD */
WITH n_appelli_ad AS (

	SELECT t1.cdscod, t1.adcod, COUNT(*) AS numero_appelli
	FROM (
		SELECT DISTINCT CdSCod, adcod, DtAppello, docente
		FROM bos_denormalizzato
		WHERE appello_chiuso = 1
	) AS t1
	GROUP BY t1.cdscod, t1.adcod
	HAVING numero_appelli > 2

),

/* AVERAGE GRADE FOR AD */
voto_medio_ad AS (
	
	SELECT cdscod, adcod, AVG(voto) AS voto_medio
	FROM bos_denormalizzato
	WHERE appello_chiuso = 1
	GROUP BY cdscod, adcod

),

/* AVERAGE NUMBER OF ENROLLMENTS FOR EACH EXAM OF EACH AD */	
n_iscrizioni_medio AS (

	SELECT t1.cdscod, t1.adcod, AVG(t1.numero_iscritti) AS n_iscrizioni_media
	FROM (

		SELECT cdscod, adcod, docente, dtappello, 
			COUNT(*) AS numero_iscritti
		FROM bos_denormalizzato
		WHERE appello_chiuso = 1
		GROUP BY cdscod, adcod, docente, dtappello

	) AS t1
	GROUP BY t1.cdscod, t1.adcod
	HAVING n_iscrizioni_media >= 2
	
),

/* RATIO PASSED AND ENROLLED STUDENTS FOR EACH AD */
rapporto_promossi_iscritti AS (

	SELECT t1.cdscod, t1.adcod, 
		CAST(numero_promossi AS REAL) / CAST(numero_iscrizioni AS REAL) AS ratio_promossi_iscritti
	FROM (

		SELECT cdscod, adcod, COUNT(*) AS numero_iscrizioni,
			SUM(CASE WHEN Superamento = 1 THEN 1 ELSE 0 END) AS numero_promossi
		FROM bos_denormalizzato
		WHERE appello_chiuso = 1
		GROUP BY cdscod, adcod	

	) AS t1
	
)

/* DIFFICULTY SCORE RANKING */
SELECT *
FROM (

	SELECT t1.*, 
		ROUND((t1.voto_medio_norm * 0.7) + (t1.ratio_promossi_iscritti * 0.3), 3) AS rating,
		DENSE_RANK() OVER( PARTITION BY t1.cdscod ORDER BY (t1.voto_medio_norm * 0.7) + (t1.ratio_promossi_iscritti * 0.3) DESC, t1.numero_appelli DESC ) AS rank_best,
		DENSE_RANK() OVER( PARTITION BY t1.cdscod ORDER BY (t1.voto_medio_norm * 0.7) + (t1.ratio_promossi_iscritti * 0.3) ASC, t1.numero_appelli DESC ) AS rank_worst
	FROM (

		SELECT n_appelli_ad.*, 
			ROUND(voto_medio_ad.voto_medio, 3) AS voto_medio, 
			ROUND((voto_medio_ad.voto_medio - 18.0) / 12.0, 3) AS voto_medio_norm, 
			ROUND(n_iscrizioni_medio.n_iscrizioni_media, 3) AS n_iscrizioni_media,
			ROUND(rapporto_promossi_iscritti.ratio_promossi_iscritti, 3) AS ratio_promossi_iscritti
		FROM n_appelli_ad
		INNER JOIN voto_medio_ad ON voto_medio_ad.cdscod = n_appelli_ad.cdscod
			AND voto_medio_ad.adcod = n_appelli_ad.adcod
		INNER JOIN n_iscrizioni_medio ON n_iscrizioni_medio.cdscod = n_appelli_ad.cdscod
			AND n_iscrizioni_medio.adcod = n_appelli_ad.adcod
		INNER JOIN rapporto_promossi_iscritti ON rapporto_promossi_iscritti.cdscod = n_appelli_ad.cdscod
			AND rapporto_promossi_iscritti.adcod = n_appelli_ad.adcod
			
	) AS t1
	
) AS t2
WHERE t2.rank_best <= 3 OR t2.rank_worst <= 3;

