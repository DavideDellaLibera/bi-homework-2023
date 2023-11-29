
/* DOMANDA 3 - NORM */ 

/* VIEW: COMMITMENT RATES */
DROP VIEW IF EXISTS query3_commitment_rates;
CREATE VIEW IF NOT EXISTS query3_commitment_rates AS

	/* COMPUTATION OF THE PERCENTILE RANK */
	SELECT commitment_rates.cdscod, 
		commitment_rates.commitment_rate,
		ROUND(PERCENT_RANK() OVER (ORDER BY commitment_rates.commitment_rate), 3) AS percentile_rank
		
	FROM (

		/* COMMITMENT RATE FORMULA */
		SELECT *,
			ROUND(0.7 * ( ( CAST(numero_date_overlap AS REAL) / CAST(numero_date AS REAL) ) * 
			( CAST(numero_esami_date_overlap AS REAL) / CAST(numero_date_overlap AS REAL) ) ) + 
			0.3 * ( CAST(numero_ad AS REAL) / CAST(numero_appelli AS REAL) ), 3) AS commitment_rate
		FROM (

			/* PARAMS TO COMPUTE THE COMMITMENT RATE */
			SELECT cds_commitment_count.cdscod, cds_numero_ad.numero_ad, 
				SUM(cds_commitment_count.n_distinct_ad) AS numero_appelli,
				SUM(CASE WHEN cds_commitment_count.n_distinct_ad > 1 THEN 1 ELSE 0 END) AS numero_date_overlap,
				COUNT(*) AS numero_date,
				SUM(CASE WHEN cds_commitment_count.n_distinct_ad > 1 THEN n_distinct_ad ELSE 0 END) AS numero_esami_date_overlap
				
			FROM (
				
				/* NUMBER OF DISTINCT AD FOR EACH CDS */
				SELECT stats_appelli.cdscod, stats_appelli.dtappello, 
					COUNT(DISTINCT stats_appelli.adcod) AS n_distinct_ad
				FROM stats_appelli
				GROUP BY stats_appelli.cdscod, stats_appelli.dtappello
				
			) AS cds_commitment_count
			
			LEFT JOIN (
				
				/* NUMBER OF AD FOR EACH CDS */
				SELECT stats_appelli.cdscod, COUNT(DISTINCT stats_appelli.adcod) AS numero_ad
				FROM stats_appelli
				GROUP BY stats_appelli.cdscod
				
			) AS cds_numero_ad ON cds_numero_ad.cdscod = cds_commitment_count.cdscod
			GROUP BY cds_commitment_count.cdscod
			
		) AS params_commitment
		
	) AS commitment_rates
	ORDER BY commitment_rates.commitment_rate DESC;

	