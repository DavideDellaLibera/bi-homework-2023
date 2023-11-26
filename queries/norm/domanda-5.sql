
/* DOMANDA 5 - NORM */

/* VIEW: MESI (PERIODO) ATTIVITA STUDENTI (FAST) */
DROP VIEW IF EXISTS query5_fast_studenti;
CREATE VIEW IF NOT EXISTS query5_fast_studenti AS

	SELECT appelli.cdscod, iscrizioni.studente, 
		CAST(ROUND((JULIANDAY(DATE(MAX(dtappello), 'start of month')) - JULIANDAY(DATE(MIN(dtappello), 'start of month'))) / 30) + 1 AS INTEGER) AS mesi_att
	FROM iscrizioni
	JOIN appelli ON appelli.appcod = iscrizioni.appcod
	WHERE appelli.appello_chiuso = 1
	GROUP BY appelli.cdscod, iscrizioni.studente;

	
/* VIEW: PARAMETRI FURIOUS */
DROP VIEW IF EXISTS query5_furious_studenti;
CREATE VIEW IF NOT EXISTS query5_furious_studenti AS	

	SELECT t1.cdscod, t1.studente, t1.n_esami_superati, (CASE WHEN t1.voto_medio IS NULL THEN 0 ELSE t1.voto_medio END) AS voto_medio,
		CAST((CAST(t1.n_esami_superati AS REAL) / CAST(n_iscrizioni AS REAL)) AS REAL) AS tasso_successo
	FROM (

		SELECT appelli.cdscod, iscrizioni.studente, SUM(CASE WHEN iscrizioni.Superamento = 1 THEN 1 ELSE 0 END) AS n_esami_superati,
			COUNT(*) AS n_iscrizioni, ROUND(AVG(iscrizioni.voto), 3) AS voto_medio	
		FROM iscrizioni
		JOIN appelli ON appelli.appcod = iscrizioni.appcod
		WHERE appelli.appello_chiuso = 1
		GROUP BY appelli.cdscod, iscrizioni.studente
		
	) AS t1;
	

/* VIEW: FAST AND FURIOUS STUDENTI */
DROP VIEW IF EXISTS query5_fast_and_furious;
CREATE VIEW IF NOT EXISTS query5_fast_and_furious AS

	SELECT t1.*, 
		ROUND(t1.mesi_att_norm * 0.25 + t1.tasso_successo * 0.25 + t1.voto_medio_norm * 0.25 + t1.n_esami_superati_norm * 0.25, 3) AS fast_and_furious
	FROM (

		SELECT query5_furious_studenti.cdscod, query5_furious_studenti.studente,
			query5_furious_studenti.tasso_successo,
			query5_furious_studenti.voto_medio, query5_furious_studenti.voto_medio / 30 AS voto_medio_norm,
			query5_furious_studenti.n_esami_superati, CAST(query5_furious_studenti.n_esami_superati AS REAL) / MAX(query5_furious_studenti.n_esami_superati) OVER( PARTITION BY query5_furious_studenti.cdscod ORDER BY query5_furious_studenti.n_esami_superati DESC ) AS n_esami_superati_norm,
			query5_fast_studenti.mesi_att, 1 - CAST(((query5_fast_studenti.mesi_att - 1) / 12.0) AS REAL) AS mesi_att_norm
			
		FROM query5_furious_studenti
		INNER JOIN query5_fast_studenti ON query5_fast_studenti.cdscod = query5_furious_studenti.cdscod
			AND query5_fast_studenti.studente = query5_furious_studenti.studente
			
	) AS t1;

	
/* VIEW: RANKINGS FAST AND FURIOUS */
DROP VIEW IF EXISTS query5_rankings_fast_and_furious;
CREATE VIEW IF NOT EXISTS query5_rankings_fast_and_furious AS

	SELECT query5_fast_and_furious.cdscod, query5_fast_and_furious.studente, query5_fast_and_furious.fast_and_furious,
		DENSE_RANK() OVER( 
			PARTITION BY cdscod
			ORDER BY fast_and_furious DESC
		) AS rank_fast_and_furious
	FROM query5_fast_and_furious
		
