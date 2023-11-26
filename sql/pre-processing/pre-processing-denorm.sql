
/* PRE-PROCESSING DENORM */

/* PROBLEMA 1: DATE MANAGEMENT */
UPDATE bos_denormalizzato_processed
SET DtAppello = (

    SELECT DATE( SUBSTR( SUBSTR(DtAppello, INSTR(DtAppello, '/') + 1), INSTR(SUBSTR(DtAppello, INSTR(DtAppello, '/') + 1), '/') + 1) || '-' ||
		SUBSTR( SUBSTR(DtAppello, INSTR(DtAppello, '/') + 1), 1, INSTR( SUBSTR(DtAppello, INSTR(DtAppello, '/') + 1), '/' ) - 1 ) || '-' ||
		SUBSTR( DtAppello, 1, INSTR(DtAppello, '/') - 1 ) )
	FROM bos_denormalizzato_processed AS t1
    WHERE t1.rowid = bos_denormalizzato_processed.rowid
	
);


/* PROBLEMA 2: ELIMINAZIONE AD SENZA VOTO */
DELETE FROM bos_denormalizzato_processed
WHERE bos_denormalizzato_processed.adcod IN (
	SELECT adcod_deleted_extra.adcod
	FROM adcod_deleted_extra
);


/* PROBLEMA 3: ELIMINAZIONE DELLA COLONNA ISCRIZIONE */
ALTER TABLE bos_denormalizzato_processed DROP COLUMN Iscrizione;


/* PROBLEMA 4: ELIMINAZIONE PER DATA FUORI DAL PERIODO CONSIDERATO */
DELETE FROM bos_denormalizzato_processed
WHERE STRFTIME("%Y-%m", dtappello) < '2016-11'
	OR STRFTIME("%Y-%m", dtappello) > '2017-12';

	
/* PROBLEMA 5: AGGIUSTAMENTO STESSO CDS */
UPDATE bos_denormalizzato_processed
SET cdscod = 'E2004P'
WHERE cdscod = 'E2003P';

UPDATE bos_denormalizzato_processed
SET cdscod = 'E1901R'
WHERE cdscod = '524';

UPDATE bos_denormalizzato_processed
SET cdscod = 'E1501N'
WHERE cdscod = '541' 
	OR cdscod = 'E1502N';
	
UPDATE bos_denormalizzato_processed
SET cdscod = 'F8204B'
WHERE cdscod = 'F8202B';


/* ROBLEMA 6: APPELLO APERTO CHIUSO */
ALTER TABLE bos_denormalizzato_processed
ADD COLUMN appello_chiuso INTEGER;

UPDATE bos_denormalizzato_processed
SET appello_chiuso = 1;

DROP TABLE IF EXISTS bos_denormalizzato;
CREATE TABLE IF NOT EXISTS bos_denormalizzato AS

	SELECT bos_denormalizzato_processed.*, (CASE WHEN t1.appello_chiuso IS NULL THEN 1 ELSE 0 END) AS appello_chiuso_temp
	FROM bos_denormalizzato_processed
	LEFT JOIN (
		
		SELECT appelli.* 
		FROM app_open_closed
		INNER JOIN appelli ON appelli.appcod = app_open_closed.appcod
		WHERE app_open_closed.appello_chiuso = 0

	) AS t1 ON t1.cdscod = bos_denormalizzato_processed.CdSCod
		AND t1.adcod = bos_denormalizzato_processed.adcod
		AND t1.docente = bos_denormalizzato_processed.docente
		AND t1.dtappello = bos_denormalizzato_processed.dtappello;
		
ALTER TABLE bos_denormalizzato
DROP COLUMN appello_chiuso;

DROP TABLE IF EXISTS bos_denormalizzato_processed;


/* INDEXES */
CREATE INDEX bos_denormalizzato_AD ON bos_denormalizzato(AD);
CREATE INDEX bos_denormalizzato_AdCod ON bos_denormalizzato(AdCod);
CREATE INDEX bos_denormalizzato_AdSettCod ON bos_denormalizzato(AdSettCod);
CREATE INDEX bos_denormalizzato_CdS ON bos_denormalizzato(CdS);
CREATE INDEX bos_denormalizzato_CdSCod ON bos_denormalizzato(CdSCod);
CREATE INDEX bos_denormalizzato_Docente ON bos_denormalizzato(Docente);

