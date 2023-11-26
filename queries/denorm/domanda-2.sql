
/* QUERY 2 - DENORM */

WITH app_difficulty AS (

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

media_tentativi_stud_ad AS (

	/* MEDIA TENTATIVI PER STUDENTE PER ATTIVITA DIDATTICA */
	SELECT t1.cdscod, t1.adcod, ROUND(AVG(t1.numero_tentativi), 3) AS media_tentativi
	FROM (
		SELECT studente, cdscod, adcod, COUNT(*) AS numero_tentativi
		FROM bos_denormalizzato
		WHERE appello_chiuso = 1
		GROUP BY studente, cdscod, adcod
	) AS t1
	GROUP BY t1.cdscod, t1.adcod

),

ts_mediano_ad AS (
	
	/* TASSO SUPERAMENTO MEDIANO DEL AD */
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

voto_agg_mediano_ad AS (
	
	/* VOTO AGGREGATO MEDIANO DEL AD */
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

numero_appelli_ad AS (

	SELECT app_difficulty.cdscod, app_difficulty.adcod, COUNT(*) AS numero_appelli
	FROM app_difficulty
	GROUP BY app_difficulty.cdscod, app_difficulty.adcod
	HAVING numero_appelli > 1

)

SELECT *
FROM (

	SELECT *, DENSE_RANK() OVER( PARTITION BY rankings_agg.cdscod ORDER BY rankings_agg.rank_pesato ASC ) AS rank_position
	FROM (

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
		
	) AS rankings_agg
	
) AS result
WHERE rank_position <= 10;

