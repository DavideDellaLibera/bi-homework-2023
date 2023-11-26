
/* QUERY 2 - NORM */

/* VIEW: STATISTICHE DIFFICOLTA PER CIASCUN APPELLO */
DROP VIEW IF EXISTS query2_app_difficulty;
CREATE VIEW IF NOT EXISTS query2_app_difficulty AS

	SELECT stats_appelli.appcod, stats_appelli.cdscod, stats_appelli.adcod, 
		stats_appelli.numero_iscritti, stats_appelli.tasso_superamento, 
		
		CASE WHEN stats_appelli.voto_medio IS NOT NULL AND stats_appelli.voto_mediano IS NULL
			THEN ROUND( ( stats_appelli.voto_medio + ROUND((stats_appelli.tasso_superamento / (0.498/16) + 1), 1 )) / 2, 3 )
			ELSE CASE WHEN stats_appelli.voto_medio IS NULL
				THEN 0 ELSE ROUND((stats_appelli.voto_medio + stats_appelli.voto_mediano) / 2, 3)
			END
		END AS voto_agg

	FROM stats_appelli
	WHERE stats_appelli.appello_chiuso = 1;

	
/* VIEW: MEDIA TENTATIVI PER STUDENTE PER ATTIVITA DIDATTICA */
DROP VIEW IF EXISTS query2_ad_media_tentativi;
CREATE VIEW IF NOT EXISTS query2_ad_media_tentativi AS

	SELECT tentativi_studenti.cdscod, tentativi_studenti.adcod, 
		ROUND(AVG(tentativi_studenti.numero_tentativi), 3) AS media_tentativi
	FROM (

		SELECT iscrizioni.studente, query2_app_difficulty.cdscod, query2_app_difficulty.adcod, 
			COUNT(*) AS numero_tentativi
		FROM iscrizioni
		INNER JOIN query2_app_difficulty ON query2_app_difficulty.appcod = iscrizioni.appcod
		GROUP BY iscrizioni.studente, query2_app_difficulty.cdscod, query2_app_difficulty.adcod
		
	) AS tentativi_studenti
	GROUP BY tentativi_studenti.cdscod, tentativi_studenti.adcod;

	
/* VIEW: MEDIANA TASSO DI SUPERAMENTO PER ATTIVITA DIDATTICA */
DROP VIEW IF EXISTS query2_ad_mediana_ts;
CREATE VIEW IF NOT EXISTS query2_ad_mediana_ts AS

	SELECT ranking.cdscod, ranking.adcod, ROUND(AVG(ranking.tasso_superamento), 3) AS ts_mediano
	FROM (
		SELECT *,
			ROW_NUMBER() OVER (PARTITION BY query2_app_difficulty.cdscod, query2_app_difficulty.adcod ORDER BY query2_app_difficulty.tasso_superamento ASC) AS rank_ts,
			COUNT(*) OVER (PARTITION BY query2_app_difficulty.cdscod, query2_app_difficulty.adcod) AS numero_appelli
		FROM query2_app_difficulty
	) AS ranking
	WHERE rank_ts IN ((ranking.numero_appelli + 1) / 2, (ranking.numero_appelli + 2) / 2)
	GROUP BY ranking.cdscod, ranking.adcod;

	
/* VIEW: MEDIANA VOTO AGGREGATO (APPELLI) PER ATTIVITA DIDATTICA */
DROP VIEW IF EXISTS query2_ad_mediana_voto_agg;
CREATE VIEW IF NOT EXISTS query2_ad_mediana_voto_agg AS

	SELECT ranking.cdscod, ranking.adcod, ROUND(AVG(ranking.voto_agg), 3) AS voto_agg_mediano
	FROM (
		SELECT *,
			ROW_NUMBER() OVER(
				PARTITION BY query2_app_difficulty.cdscod, query2_app_difficulty.adcod 
				ORDER BY query2_app_difficulty.voto_agg ASC
			) AS rank_appello,
			COUNT(*) OVER(
				PARTITION BY query2_app_difficulty.cdscod, query2_app_difficulty.adcod
			) AS numero_appelli
		FROM query2_app_difficulty
	) AS ranking
	WHERE rank_appello IN ((ranking.numero_appelli + 1) / 2, (ranking.numero_appelli + 2) / 2)
	GROUP BY ranking.cdscod, ranking.adcod;

	
/* VIEW: DIFFICOLTA ATTIVITA DIDATTICA PER CORSO DI STUDIO */
DROP VIEW IF EXISTS query2_cds_ad_difficulty;
CREATE VIEW IF NOT EXISTS query2_cds_ad_difficulty AS

	SELECT ad_difficulty.cdscod, ad_difficulty.adcod, ad_difficulty.numero_appelli,
		query2_ad_media_tentativi.media_tentativi, query2_ad_mediana_voto_agg.voto_agg_mediano, query2_ad_mediana_ts.ts_mediano
	FROM (
		
		/* CALCOLO DEL NUMERO DI APPELLI PER ATTIVITA DIDATTICA */
		SELECT query2_app_difficulty.cdscod, query2_app_difficulty.adcod, COUNT(*) AS numero_appelli
		FROM query2_app_difficulty
		GROUP BY query2_app_difficulty.cdscod, query2_app_difficulty.adcod
		HAVING numero_appelli > 1

	) AS ad_difficulty

	INNER JOIN query2_ad_media_tentativi ON query2_ad_media_tentativi.cdscod = ad_difficulty.cdscod
		AND query2_ad_media_tentativi.adcod = ad_difficulty.adcod
		
	INNER JOIN query2_ad_mediana_voto_agg ON query2_ad_mediana_voto_agg.cdscod = ad_difficulty.cdscod
		AND query2_ad_mediana_voto_agg.adcod = ad_difficulty.adcod
		
	INNER JOIN query2_ad_mediana_ts ON query2_ad_mediana_ts.cdscod = ad_difficulty.cdscod
		AND query2_ad_mediana_ts.adcod = ad_difficulty.adcod;
	

/* VIEW: RANKING PER CIASCUN PARAMETRO PER CORSO DI STUDI */
DROP VIEW IF EXISTS query2_rankings_params;
CREATE VIEW IF NOT EXISTS query2_rankings_params AS

	SELECT query2_cds_ad_difficulty.cdscod, query2_cds_ad_difficulty.adcod,

		DENSE_RANK() OVER( 
			PARTITION BY query2_cds_ad_difficulty.cdscod
			ORDER BY query2_cds_ad_difficulty.ts_mediano ASC
		) AS rank_ts,
		
		DENSE_RANK() OVER( 
			PARTITION BY query2_cds_ad_difficulty.cdscod
			ORDER BY query2_cds_ad_difficulty.voto_agg_mediano ASC
		) AS rank_voto_agg,
		
		DENSE_RANK() OVER( 
			PARTITION BY query2_cds_ad_difficulty.cdscod
			ORDER BY query2_cds_ad_difficulty.media_tentativi DESC
		) AS rank_media_tentativi
		
	FROM query2_cds_ad_difficulty;
	
	
/* VIEW: ALGORITMO RANKING */	
DROP VIEW IF EXISTS query2_rankings;
CREATE VIEW IF NOT EXISTS query2_rankings AS

	SELECT t1.*,
		DENSE_RANK() OVER( 
			PARTITION BY t1.cdscod
			ORDER BY t1.rank_pesato ASC
		) AS rank_position
		
	FROM (
		SELECT cdscod, adcod, rank_ts * 0.4 + rank_voto_agg * 0.3 + rank_media_tentativi * 0.3 AS rank_pesato
		FROM query2_rankings_params
	) AS t1
	

