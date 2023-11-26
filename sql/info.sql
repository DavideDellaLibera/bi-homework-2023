
/* INFORMAZIONI GENERALI PER CDS */
DROP VIEW IF EXISTS general_info_cds;
CREATE VIEW IF NOT EXISTS general_info_cds AS 

	SELECT tabella_globale.cdscod, cds.cds, cds.tipocorso,
	
		cds_stats.numero_ad, cds_stats.numero_docenti,
		
		COUNT(*) AS numero_studenti, 

		SUM(CASE WHEN tabella_globale.genere = 'F' THEN 1 ELSE 0 END) AS donne,
		SUM(CASE WHEN tabella_globale.genere = 'M' THEN 1 ELSE 0 END) AS uomini,
		
		SUM(CASE WHEN tabella_globale.citttipo = 'Italiana' THEN 1 ELSE 0 END) AS ita,
		SUM(CASE WHEN tabella_globale.citttipo = 'Comunitaria' THEN 1 ELSE 0 END) AS eu,
		SUM(CASE WHEN tabella_globale.citttipo = 'Extra Comunitaria' THEN 1 ELSE 0 END) AS extra_eu,
		
		SUM(CASE WHEN tabella_globale.resarea = 'REGIONE' THEN 1 ELSE 0 END) AS regione,
		SUM(CASE WHEN tabella_globale.resarea = 'PROVINCIA' THEN 1 ELSE 0 END) AS provincia,
		SUM(CASE WHEN tabella_globale.resarea = 'CITTA' THEN 1 ELSE 0 END) AS citta,
		SUM(CASE WHEN tabella_globale.resarea = 'EXTRA-REGIONE' THEN 1 ELSE 0 END) AS extra_regione,
		
		SUM(CASE WHEN tabella_globale.etaimm = '18' THEN 1 ELSE 0 END) AS eta_18,
		SUM(CASE WHEN tabella_globale.etaimm = '19' THEN 1 ELSE 0 END) AS eta_19,
		SUM(CASE WHEN tabella_globale.etaimm = '20' THEN 1 ELSE 0 END) AS eta_20,
		SUM(CASE WHEN tabella_globale.etaimm = '21' THEN 1 ELSE 0 END) AS eta_21,
		SUM(CASE WHEN tabella_globale.etaimm = '22' THEN 1 ELSE 0 END) AS eta_22,
		SUM(CASE WHEN tabella_globale.etaimm = '23-27' THEN 1 ELSE 0 END) AS eta_23_27,
		SUM(CASE WHEN tabella_globale.etaimm = '28+' THEN 1 ELSE 0 END) AS eta_28
		
	FROM (

		SELECT appelli.cdscod, studenti.studente, 
			studenti.genere, studenti.resarea, studenti.etaimm, studenti.citttipo
		FROM iscrizioni
		INNER JOIN appelli ON appelli.appcod = iscrizioni.appcod
		INNER JOIN studenti ON studenti.studente = iscrizioni.studente
		GROUP BY appelli.cdscod, studenti.studente
		
	) AS tabella_globale
	INNER JOIN (
		
		SELECT appelli.cdscod,
			COUNT(DISTINCT adcod) AS numero_ad,
			COUNT(DISTINCT docente) AS numero_docenti
		FROM iscrizioni
		INNER JOIN appelli ON appelli.appcod = iscrizioni.appcod
		INNER JOIN studenti ON studenti.studente = iscrizioni.studente
		GROUP BY appelli.cdscod
	
	) AS cds_stats ON cds_stats.cdscod = tabella_globale.cdscod
	INNER JOIN cds ON cds.cdscod = tabella_globale.cdscod

	GROUP BY tabella_globale.cdscod;



