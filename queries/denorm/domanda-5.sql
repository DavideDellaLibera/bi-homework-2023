
/* DOMANDA 5 - DENORM */

/* CALCOLO FAST AND FURIOUS INDEX */
WITH fast_and_furious_index AS (
	SELECT t3.*, 
		ROUND(t3.mesi_att_norm * 0.25 + t3.tasso_successo * 0.25 + t3.voto_medio_norm * 0.25 + t3.n_esami_superati_norm * 0.25, 3) AS fast_and_furious
	FROM (

		SELECT params_fast.cdscod, params_fast.studente,
			params_fast.mesi_att, 1 - CAST(((params_fast.mesi_att - 1) / 12.0) AS REAL) AS mesi_att_norm,
			params_furious.tasso_successo,
			params_furious.voto_medio, params_furious.voto_medio / 30 AS voto_medio_norm,
			params_furious.n_esami_superati, CAST(params_furious.n_esami_superati AS REAL) / MAX(params_furious.n_esami_superati) OVER( PARTITION BY params_furious.cdscod ORDER BY params_furious.n_esami_superati DESC ) AS n_esami_superati_norm
				
		FROM (

			/* MESI (PERIODO) ATTIVITA STUDENTI (FAST) */
			SELECT cdscod, studente, 
				CAST(ROUND((JULIANDAY(DATE(MAX(dtappello), 'start of month')) - JULIANDAY(DATE(MIN(dtappello), 'start of month'))) / 30) + 1 AS INTEGER) AS mesi_att
			FROM bos_denormalizzato
			WHERE appello_chiuso = 1
			GROUP BY cdscod, studente
			
		) AS params_fast
		INNER JOIN (

			/* PARAMETRI FURIOUS */
			SELECT t1.cdscod, t1.studente, t1.n_esami_superati, 
				(CASE WHEN t1.voto_medio IS NULL THEN 0 ELSE t1.voto_medio END) AS voto_medio,
				(CAST(t1.n_esami_superati AS REAL) / CAST(n_iscrizioni AS REAL)) AS tasso_successo
			FROM (
				
				SELECT cdscod, studente, COUNT(*) AS n_iscrizioni, 
					SUM(CASE WHEN Superamento = 1 THEN 1 ELSE 0 END) AS n_esami_superati, AVG(voto) AS voto_medio
				FROM bos_denormalizzato
				WHERE appello_chiuso = 1
				GROUP BY cdscod, studente

			) AS t1
			
		) AS params_furious ON params_furious.cdscod = params_fast.cdscod
			AND params_furious.studente = params_fast.studente
			
	) AS t3
	
)

/* RANKINGS F&F INDEX */
SELECT fast_and_furious_index.cdscod, fast_and_furious_index.studente, fast_and_furious_index.fast_and_furious,
	DENSE_RANK() OVER( 
		PARTITION BY cdscod
		ORDER BY fast_and_furious DESC
	) AS rank_fast_and_furious
FROM fast_and_furious_index	


