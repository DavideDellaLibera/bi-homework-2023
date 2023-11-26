
/* TABELLA: STATISTICHE APPELLI */
DROP TABLE IF EXISTS stats_appelli;
CREATE TABLE IF NOT EXISTS stats_appelli AS

	SELECT appelli.appcod, appelli.cdscod, appelli.adcod, appelli.docente, 
		appelli.dtappello, appelli.appello_chiuso,
	
		CASE WHEN stats_appelli_temp.numero_iscritti IS NULL 
			THEN 0 
			ELSE stats_appelli_temp.numero_iscritti
		END AS numero_iscritti,
		
		stats_appelli_temp.numero_promossi,
		
		CASE WHEN appelli.appello_chiuso = 0
			THEN 0
			ELSE stats_appelli_temp.numero_bocciati
		END AS numero_bocciati, 
		
		stats_appelli_temp.numero_insufficienti,
		stats_appelli_temp.numero_ritirati, stats_appelli_temp.numero_assenti,
		stats_appelli_temp.tasso_superamento, stats_appelli_temp.voto_medio, 
		(stats_appelli_temp.voto_medio * stats_appelli_temp.numero_promossi) AS voto_medio_freq, 
		stats_appelli_temp.voto_mediano
		
	FROM appelli
	LEFT JOIN(

		SELECT iscrizioni.appcod, 

			COUNT(*) AS numero_iscritti,
			SUM(CASE WHEN iscrizioni.Superamento = 1 THEN 1 ELSE 0 END) AS numero_promossi, 
			SUM(CASE WHEN iscrizioni.Superamento = 0 THEN 1 ELSE 0 END) AS numero_bocciati,
			SUM(CASE WHEN iscrizioni.Insufficienza = 1 THEN 1 ELSE 0 END) AS numero_insufficienti,
			SUM(CASE WHEN iscrizioni.Ritiro = 1 THEN 1 ELSE 0 END) AS numero_ritirati,
			SUM(CASE WHEN iscrizioni.Assenza = 1 THEN 1 ELSE 0 END) AS numero_assenti,
			ROUND(CAST(SUM(CASE WHEN iscrizioni.Superamento = 1 THEN 1 ELSE 0 END) AS REAL) / CAST(COUNT(*) AS REAL), 3) AS tasso_superamento,
			ROUND(AVG(iscrizioni.Voto), 3) AS voto_medio,
			voto_mediano_appelli.voto_mediano
			
		FROM iscrizioni
		LEFT JOIN (

			SELECT ranking.appcod, AVG(ranking.Voto) AS voto_mediano
			FROM (
				SELECT iscrizioni.appcod, iscrizioni.Voto,
					ROW_NUMBER() OVER (PARTITION BY iscrizioni.appcod ORDER BY iscrizioni.Voto ASC) AS rank_voto,
					COUNT(*) OVER (PARTITION BY iscrizioni.appcod) AS numero_iscritti
				FROM iscrizioni
				INNER JOIN appelli ON appelli.appcod = iscrizioni.appcod
			) AS ranking
			WHERE rank_voto IN ((ranking.numero_iscritti + 1) / 2, (ranking.numero_iscritti + 2) / 2)
			GROUP BY ranking.appcod

		) AS voto_mediano_appelli ON voto_mediano_appelli.appcod = iscrizioni.appcod
		GROUP BY iscrizioni.appcod
		
	) AS stats_appelli_temp ON stats_appelli_temp.appcod = appelli.appcod;
