
/* DOMANDA 4 - NORM */

/* VIEW: PARAMETRI E RANK VOTO MEDIO BEST/WORST */
DROP VIEW IF EXISTS query4_rank_voto_medio;
CREATE VIEW IF NOT EXISTS query4_rank_voto_medio AS

	SELECT t1.cdscod, t1.adcod, t1.voto_medio_norm, t1.ratio_promossi_iscritti,
		ROUND((t1.voto_medio_norm * 0.7) + (t1.ratio_promossi_iscritti * 0.3), 3) AS rating,
		DENSE_RANK() OVER( PARTITION BY t1.cdscod ORDER BY ((t1.voto_medio_norm * 0.7) + (t1.ratio_promossi_iscritti * 0.3)) DESC, numero_appelli DESC ) AS rank_best,
		DENSE_RANK() OVER( PARTITION BY t1.cdscod ORDER BY ((t1.voto_medio_norm * 0.7) + (t1.ratio_promossi_iscritti * 0.3)) ASC, numero_appelli DESC ) AS rank_worst
	FROM (
	
		SELECT stats_appelli.cdscod, stats_appelli.adcod, COUNT(*) AS numero_appelli,
			ROUND(CAST(SUM(stats_appelli.numero_iscritti) AS REAL) / CAST(COUNT(*) AS REAL), 3) AS n_iscrizioni_media,
			ROUND(SUM(stats_appelli.voto_medio_freq) / SUM(stats_appelli.numero_promossi), 3) AS voto_medio,
			ROUND(((SUM(stats_appelli.voto_medio_freq) / SUM(stats_appelli.numero_promossi)) - 18.0) / 12.0, 3) AS voto_medio_norm,
			ROUND(CAST(SUM(stats_appelli.numero_promossi) AS REAL) / CAST(SUM(stats_appelli.numero_iscritti) AS REAL), 3) AS ratio_promossi_iscritti
		FROM stats_appelli
		WHERE stats_appelli.appello_chiuso = 1
		GROUP BY stats_appelli.cdscod, stats_appelli.adcod
		HAVING numero_appelli > 2 AND n_iscrizioni_media >= 2
	
	) AS t1
	GROUP BY t1.cdscod, t1.adcod;

	
/* VIEW: TOP-3 BEST/WORST MEDIA */
DROP VIEW IF EXISTS query4_top3;
CREATE VIEW IF NOT EXISTS query4_top3 AS
	
	SELECT *
	FROM query4_rank_voto_medio
	WHERE rank_best <= 3 OR rank_worst <= 3;
  
		  