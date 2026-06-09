{{ config(materialized='table') }}

/* Tidy (long) patient demographics: one row per (dimension, category) with the
   patient count and percent of cohort. Dimensions: gender, race, age_band. The
   "90+" age band is the de-identified over-89 cohort (see kpi_admission_base). */

WITH base AS (
    SELECT * FROM {{ ref('kpi_patient_base') }}
),

total AS (SELECT count(*) AS n FROM base),

combined AS (
    SELECT 'gender'   AS dimension, gender   AS category, count(*) AS n FROM base GROUP BY 2
    UNION ALL
    SELECT 'race'     AS dimension, race     AS category, count(*) AS n FROM base GROUP BY 2
    UNION ALL
    SELECT 'age_band' AS dimension, age_band AS category, count(*) AS n FROM base GROUP BY 2
)

SELECT
    dimension,
    category,
    n AS n_patients,
    round(100.0 * n / (SELECT n FROM total), 1) AS pct_patients
FROM combined
ORDER BY dimension, n_patients DESC
