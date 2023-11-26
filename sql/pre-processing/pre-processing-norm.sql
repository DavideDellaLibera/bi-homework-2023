
/* PRE-PROCESSING NORM */

/* PROBLEMA 1: DATE APPELLI */
/* TABELLA CON APCOD FUORI DAL RANGE TEMPORALE CONSIDERATO */
DROP TABLE IF EXISTS apcod_deleted_time;
CREATE TABLE IF NOT EXISTS apcod_deleted_time AS
	SELECT appcod
	FROM appelli
	WHERE STRFTIME("%Y-%m", dtappello) IN (
		SELECT STRFTIME("%Y-%m", dtappello) AS mese_anno
		FROM appelli 
		WHERE STRFTIME("%Y-%m", dtappello) < '2016-11'
			OR STRFTIME("%Y-%m", dtappello) > '2017-12'
		GROUP BY STRFTIME("%Y-%m", dtappello)
	);

/* ELIMINAZIONE DELLE ISCRIZIONI */
DELETE FROM iscrizioni
WHERE iscrizioni.appcod IN apcod_deleted_time;

/* ELIMINAZIONE DEGLI APPELLI  */
DELETE FROM appelli
WHERE appelli.appcod IN apcod_deleted_time;


/* PROBLEMA 2: ATTIVITA DIDATTICHE SENZA VOTO */
/* APPELLI DELLE AD SENZA VOTO */
DROP TABLE IF EXISTS adcod_deleted_extra;
CREATE TABLE IF NOT EXISTS adcod_deleted_extra AS
	SELECT appelli.appcod, appelli.adcod
	FROM appelli
	WHERE appelli.adcod IN (
		SELECT DISTINCT appelli.adcod
		FROM iscrizioni
		INNER JOIN appelli ON appelli.appcod = iscrizioni.appcod
		WHERE iscrizioni.Superamento = 1 
			AND iscrizioni.Voto IS NULL
	);
	
/* ELIMINAZIONE DELLE ISCRIZIONI */
DELETE FROM iscrizioni
WHERE iscrizioni.appcod IN (
	SELECT adcod_deleted_extra.appcod
	FROM adcod_deleted_extra
);

/* ELIMINAZIONE DEGLI APPELLI */
DELETE FROM appelli
WHERE appelli.appcod IN (
	SELECT adcod_deleted_extra.appcod
	FROM adcod_deleted_extra
);

/* ELIMINAZIONE DELLE AD */ 
DELETE FROM ad
WHERE ad.adcod IN (
	SELECT adcod_deleted_extra.adcod
	FROM adcod_deleted_extra
)


/* PROBLEMA 3: STESSO CDS MA CON CODICI DIVERSI */
/* TABELLA CDS DA GESTIRE */
DROP TABLE IF EXISTS cds_duplicated;
CREATE TABLE IF NOT EXISTS cds_duplicated AS
	SELECT cds.cdscod, cds.cds, cds.tipocorso
	FROM cds
	WHERE cds.cds IN (
		SELECT cds.cds
		FROM cds
		INNER JOIN (
			SELECT appelli.cdscod, COUNT(*) AS numero_appelli
			FROM appelli
			GROUP BY appelli.cdscod
		) AS t1 ON cds.cdscod = t1.cdscod
		WHERE t1.numero_appelli < 10
	) OR cds.cdscod = 'E1501N'
	ORDER BY cds ASC;

/* AGGIORNAMENTO CODICI CDS */
UPDATE appelli
SET cdscod = 'E2004P'
WHERE cdscod = 'E2003P';

UPDATE appelli
SET cdscod = 'E1901R'
WHERE cdscod = '524';

UPDATE appelli
SET cdscod = 'E1501N'
WHERE cdscod = '541' 
	OR cdscod = 'E1502N';
	
UPDATE appelli
SET cdscod = 'F8204B'
WHERE cdscod = 'F8202B';

/* ELIMINAZIONE DEI CDS UNITI */
DELETE FROM cds
WHERE cdscod = '524'
	OR cdscod = '541'
	OR cdscod = 'E1502N'
	OR cdscod = 'F8202B'
	OR cdscod = 'E2003P';
	
	
/* PROBLEMA 4: APPELLI APERTI E CHIUSI */
DROP TABLE IF EXISTS app_open_closed;
CREATE TABLE IF NOT EXISTS app_open_closed AS	
	SELECT t2.appcod, 
		CASE WHEN t2.appello_chiuso = 1
			THEN 1 
			ELSE CASE WHEN t2.dtappello = t3.max_data
				THEN 0 ELSE 1
			END
		END AS appello_chiuso
	FROM (
	
		SELECT appelli.appcod, appelli.cdscod, appelli.adcod, appelli.dtappello, t1.appello_chiuso
		FROM appelli
		INNER JOIN (

			SELECT iscrizioni.appcod, iscrizioni_problematiche.iscrizioni_prob, COUNT(*) AS numero_iscritti,
				
				CASE WHEN COUNT(*) > iscrizioni_problematiche.iscrizioni_prob
				THEN 1 ELSE 0
				END AS appello_chiuso
				
			FROM iscrizioni
			INNER JOIN (
				
				SELECT iscrizioni.appcod, COUNT(*) AS iscrizioni_prob
				FROM iscrizioni
				WHERE iscrizioni.Superamento = 0 
					AND iscrizioni.Insufficienza = 0
					AND iscrizioni.Ritiro = 0
					AND iscrizioni.Assenza = 0
				GROUP BY iscrizioni.appcod

			) AS iscrizioni_problematiche ON iscrizioni_problematiche.appcod = iscrizioni.appcod
			GROUP BY iscrizioni.appcod
			
		) AS t1 ON t1.appcod = appelli.appcod
		
	) AS t2
	INNER JOIN (

		SELECT appelli.cdscod, appelli.adcod, MAX(appelli.dtappello) AS max_data
		FROM appelli
		GROUP BY appelli.cdscod, appelli.adcod
		ORDER BY max_data

	) AS t3 ON t3.cdscod = t2.cdscod
		AND t2.adcod = t3.adcod;
		
/* AGGIORNAMENTO: ALGORITMO IF APPELLO CHIUSO */
UPDATE iscrizioni
SET Assenza = 1
WHERE isccod IN (
	
	SELECT iscrizioni.isccod
	FROM iscrizioni
	INNER JOIN app_open_closed ON app_open_closed.appcod = iscrizioni.appcod
	WHERE app_open_closed.appello_chiuso = 1
	
) AND iscrizioni.Superamento = 0 
	AND iscrizioni.Insufficienza = 0
	AND iscrizioni.Ritiro = 0
	AND iscrizioni.Assenza = 0;

/* AGGIORNAMENTO: ALGORITMO IF APPELLO APERTO */
ALTER TABLE appelli
ADD COLUMN appello_chiuso INTEGER;

UPDATE appelli
SET appello_chiuso = 1;

UPDATE appelli
SET appello_chiuso = 0
WHERE appcod IN (
	SELECT app_open_closed.appcod
	FROM app_open_closed
	WHERE app_open_closed.appello_chiuso = 0
);

