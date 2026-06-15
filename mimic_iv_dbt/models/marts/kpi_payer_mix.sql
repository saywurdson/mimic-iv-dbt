{{ config(materialized='table') }}

/* Payer (insurance) mix across hospital admissions, from the OMOP
   payer_plan_period table (one period per admission, payer taken from
   admissions.insurance). One row per payer with the admission count, distinct
   patient count, and percent of admissions. */

WITH p AS (
    SELECT
        person_id,
        coalesce(nullif(trim(payer_source_value), ''), 'Unknown') AS payer
    FROM {{ ref('payer_plan_period') }}
),

total AS (SELECT count(*) AS n FROM p)

SELECT
    payer,
    count(*)                                    AS n_admissions,
    count(DISTINCT person_id)                   AS n_patients,
    round(100.0 * count(*) / (SELECT n FROM total), 1) AS pct_admissions
FROM p
GROUP BY payer
ORDER BY n_admissions DESC
