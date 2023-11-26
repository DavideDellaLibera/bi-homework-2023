
/* VIEW: VIZ QUERY 1 */
CREATE VIEW query1_appelli_iscritti_VIZ AS 
	SELECT query1_appelli_iscritti.cdscod, cds.cds, 
		query1_appelli_iscritti.adcod, ad.ad, 
		query1_appelli_iscritti.dtappello, 
		query1_appelli_iscritti.numero_iscritti
	FROM query1_appelli_iscritti
	JOIN cds ON cds.cdscod = query1_appelli_iscritti.cdscod
	JOIN ad ON ad.adcod = query1_appelli_iscritti.adcod;

	
CREATE VIEW query1_cds_ad_appelli_iscrizioni_VIZ AS 
	SELECT query1_cds_ad_appelli_iscrizioni.cdscod, cds.cds, 
		query1_cds_ad_appelli_iscrizioni.adcod, ad.ad, 
		query1_cds_ad_appelli_iscrizioni.anno, 
		query1_cds_ad_appelli_iscrizioni.numero_iscrizioni,
		query1_cds_ad_appelli_iscrizioni.media_iscrizioni_appello
	FROM query1_cds_ad_appelli_iscrizioni
	JOIN cds ON cds.cdscod = query1_cds_ad_appelli_iscrizioni.cdscod
	JOIN ad ON ad.adcod = query1_cds_ad_appelli_iscrizioni.adcod;
	
	
CREATE VIEW query1_cds_appelli_iscrizioni_VIZ AS 
	SELECT query1_cds_appelli_iscrizioni.cdscod, cds.cds,  
		query1_cds_appelli_iscrizioni.anno, 
		query1_cds_appelli_iscrizioni.numero_appelli,
		query1_cds_appelli_iscrizioni.numero_iscrizioni,
		query1_cds_appelli_iscrizioni.media_iscrizioni_appello
	FROM query1_cds_appelli_iscrizioni
	JOIN cds ON cds.cdscod = query1_cds_appelli_iscrizioni.cdscod;

	
/* VIEW: VIZ QUERY 2 */
CREATE VIEW query2_VIZ AS 
	SELECT query2_cds_ad_difficulty.cdscod, cds.cds, 
		query2_cds_ad_difficulty.adcod, ad.ad,
		query2_cds_ad_difficulty.media_tentativi, query2_rankings_params.rank_media_tentativi,
		query2_cds_ad_difficulty.ts_mediano, query2_rankings_params.rank_ts,
		query2_cds_ad_difficulty.voto_agg_mediano, query2_rankings_params.rank_voto_agg,
		query2_rankings.rank_pesato, query2_rankings.rank_position
	FROM query2_rankings 
	LEFT JOIN query2_cds_ad_difficulty ON query2_cds_ad_difficulty.cdscod = query2_rankings.cdscod
		AND query2_cds_ad_difficulty.adcod = query2_rankings.adcod
	INNER JOIN query2_rankings_params ON query2_rankings_params.cdscod = query2_cds_ad_difficulty.cdscod	
		AND query2_cds_ad_difficulty.adcod = query2_rankings_params.adcod
	JOIN cds ON cds.cdscod = query2_rankings.cdscod
	JOIN ad ON ad.adcod = query2_rankings.adcod;


/* VIEW: VIZ QUERY 3 */
CREATE VIEW query3_VIZ AS 
	SELECT cds.cdscod, cds.cds, query3_commitment_rates.commitment_rate,
		query3_commitment_rates.percentile_rank, query3_commitment_rates.numero_medio_sovrapposizioni, 
		query3_commitment_rates.ratio_date_overlap
	FROM query3_commitment_rates
	INNER JOIN cds ON cds.cdscod = query3_commitment_rates.cdscod
	ORDER BY query3_commitment_rates.commitment_rate DESC


/* VIEW: VIZ QUERY 4 */

/* VIEW: VIZ QUERY 5 */
DROP VIEW IF EXISTS query5_VIZ;
CREATE VIEW IF NOT EXISTS query5_VIZ AS 
	SELECT cds.*, studenti.*, query5_rankings_fast_and_furious.fast_and_furious, query5_rankings_fast_and_furious.rank_fast_and_furious,
		ROUND(query5_fast_and_furious.tasso_successo, 3) AS tasso_successo, query5_fast_and_furious.voto_medio,
		query5_fast_and_furious.n_esami_superati, query5_fast_and_furious.mesi_att
	FROM query5_fast_and_furious
	INNER JOIN query5_rankings_fast_and_furious ON query5_rankings_fast_and_furious.cdscod = query5_fast_and_furious.cdscod
		AND query5_rankings_fast_and_furious.studente = query5_fast_and_furious.studente
	INNER JOIN cds ON cds.cdscod = query5_fast_and_furious.cdscod
	INNER JOIN studenti ON studenti.studente = query5_fast_and_furious.studente;


/* VIEW: VIZ QUERY 6 */
CREATE VIEW query6_top3_cds_VIZ AS 
	SELECT query6_top3_cds.cdscod, cds.cds,  
		query6_top3_cds.trial_error, 
		query6_top3_cds.rank_trial_error
	FROM query6_top3_cds
	JOIN cds ON cds.cdscod = query6_top3_cds.cdscod;

CREATE VIEW query6_top3_cds_ad_VIZ AS 
	SELECT query6_top3_cds_ad.cdscod, cds.cds, 
		query6_top3_cds_ad.adcod, ad.ad, 
		query6_top3_cds_ad.trial_error, 
		query6_top3_cds_ad.rank_trial_error
	FROM query6_top3_cds_ad
	JOIN cds ON cds.cdscod = query6_top3_cds_ad.cdscod
	JOIN ad ON ad.adcod = query6_top3_cds_ad.adcod;	
	
CREATE VIEW query6_trial_error_ad_VIZ AS 
	SELECT query6_trial_error_ad.cdscod, cds.cds, 
		query6_trial_error_ad.adcod, ad.ad, 
		query6_trial_error_ad.n_studenti,
		query6_trial_error_ad.trial_error, 
		query6_trial_error_ad.rank_trial_error
	FROM query6_trial_error_ad
	JOIN cds ON cds.cdscod = query6_trial_error_ad.cdscod
	JOIN ad ON ad.adcod = query6_trial_error_ad.adcod;	
	
CREATE VIEW query6_trial_error_cdscod_VIZ AS 
	SELECT query6_trial_error_cdscod.cdscod, cds.cds,  
		query6_trial_error_cdscod.trial_error, 
		query6_trial_error_cdscod.rank_trial_error
	FROM query6_trial_error_cdscod
	JOIN cds ON cds.cdscod = query6_trial_error_cdscod.cdscod;
	
	
	=CONCAT(A2; " - ";B2)