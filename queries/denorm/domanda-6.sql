
/* DOMANDA 6 - DENORM */

/* STUDENTS STATS AND TRIAL/ERROR INDEX FOR EACH AD */
WITH trial_error_stud_ad AS (
	
	SELECT cdscod, adcod, studente,
		(CAST(t1.n_insufficienze * 1.5 + t1.n_ritiri * 1 + t1.n_assenze * 0.5 AS REAL)) AS trial_error
	FROM (

		SELECT cdscod, adcod, studente,
			SUM(CASE WHEN Insufficienza = 1 THEN 1 ELSE 0 END) AS n_insufficienze,
			SUM(CASE WHEN Ritiro = 1 THEN 1 ELSE 0 END) AS n_ritiri,
			SUM(CASE WHEN Assenza = 1 THEN 1 ELSE 0 END) AS n_assenze
		FROM bos_denormalizzato
		WHERE appello_chiuso = 1
		GROUP BY cdscod, adcod, studente
		
	) AS t1

)

/* TRIAL&ERROR INDEX FOR AD */
SELECT *
FROM (

	SELECT cdscod, adcod, COUNT(*) AS n_studenti,
		ROUND(AVG(trial_error), 3) AS trial_error,
		DENSE_RANK() OVER( PARTITION BY cdscod ORDER BY ROUND(AVG(trial_error), 3) DESC) AS rank_trial_error
	FROM trial_error_stud_ad
	GROUP BY cdscod, adcod
	HAVING n_studenti > 2
	
) AS t2
WHERE t2.rank_trial_error <= 3;

