
/* DOMANDA 3 - DENORM */ 

WITH cds_commitment_count AS (

	SELECT cdscod, dtappello, COUNT(DISTINCT adcod) AS n_distinct_ad
	FROM bos_denormalizzato
	GROUP BY cdscod, dtappello  
	
),

cds_numero_ad AS (

	SELECT cdscod, COUNT(DISTINCT adcod) AS numero_ad
	FROM bos_denormalizzato
	GROUP BY cdscod

),

cds_params AS (

	SELECT cds_commitment_count.cdscod, cds_numero_ad.numero_ad,
		SUM(cds_commitment_count.n_distinct_ad) AS numero_appelli,
		SUM(CASE WHEN cds_commitment_count.n_distinct_ad > 1 THEN 1 ELSE 0 END) AS numero_date_overlap,
		COUNT(*) AS numero_date,
		SUM(CASE WHEN cds_commitment_count.n_distinct_ad > 1 THEN n_distinct_ad ELSE 0 END) AS numero_esami_date_overlap
	FROM cds_commitment_count	
	LEFT JOIN cds_numero_ad ON cds_numero_ad.cdscod = cds_commitment_count.cdscod
	GROUP BY cds_commitment_count.cdscod

)

SELECT commitment_rates.cdscod, 
	commitment_rates.commitment_rate,
	ROUND(PERCENT_RANK() OVER (ORDER BY commitment_rates.commitment_rate), 3) AS percentile_rank
FROM (

	SELECT cds_params.cdscod,
		ROUND(0.7 * ( ( CAST(numero_date_overlap AS REAL) / CAST(numero_date AS REAL) ) * ( CAST(numero_esami_date_overlap AS REAL) / CAST(numero_date_overlap AS REAL) ) ) + 
		0.3 * ( CAST(numero_ad AS REAL) / CAST(numero_appelli AS REAL) ), 3) AS commitment_rate
	FROM cds_params
	
) AS commitment_rates
ORDER BY commitment_rate DESC

	