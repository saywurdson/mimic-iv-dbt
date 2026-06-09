{{ config(materialized='table') }}

/* Tidy (metric, value, unit) table of the headline critical-care outcomes,
   computed per hospital admission from kpi_admission_base. Rates are percent of
   admissions; length-of-stay statistics are in days. ICU LOS is restricted to
   admissions that included at least one ICU stay. */

WITH a AS (
    SELECT * FROM {{ ref('kpi_admission_base') }}
),

agg AS (
    SELECT
        count(*) AS n_adm,
        count(*) FILTER (WHERE died_in_hospital) AS n_inhosp_death,
        count(*) FILTER (WHERE died_within_30d) AS n_death_30d,
        count(*) FILTER (WHERE is_readmission_30d) AS n_readmit_30d,
        count(*) FILTER (WHERE had_icu_stay) AS n_adm_icu,
        median(hospital_los_days) AS hosp_los_med,
        quantile_cont(hospital_los_days, 0.25) AS hosp_los_p25,
        quantile_cont(hospital_los_days, 0.75) AS hosp_los_p75,
        avg(hospital_los_days) AS hosp_los_mean
    FROM a
),

icu AS (
    SELECT
        median(icu_los_days) AS icu_los_med,
        quantile_cont(icu_los_days, 0.25) AS icu_los_p25,
        quantile_cont(icu_los_days, 0.75) AS icu_los_p75,
        avg(icu_los_days) AS icu_los_mean
    FROM a
    WHERE had_icu_stay
),

metrics AS (
    SELECT 'in_hospital_mortality_rate' AS metric, 100.0 * n_inhosp_death / n_adm AS value, 'percent' AS unit, 1 AS sort FROM agg
    UNION ALL SELECT '30_day_mortality_rate', 100.0 * n_death_30d / n_adm, 'percent', 2 FROM agg
    UNION ALL SELECT '30_day_readmission_rate', 100.0 * n_readmit_30d / n_adm, 'percent', 3 FROM agg
    UNION ALL SELECT 'admissions_with_icu_pct', 100.0 * n_adm_icu / n_adm, 'percent', 4 FROM agg
    UNION ALL SELECT 'hospital_los_median', hosp_los_med, 'days', 5 FROM agg
    UNION ALL SELECT 'hospital_los_p25', hosp_los_p25, 'days', 6 FROM agg
    UNION ALL SELECT 'hospital_los_p75', hosp_los_p75, 'days', 7 FROM agg
    UNION ALL SELECT 'hospital_los_mean', hosp_los_mean, 'days', 8 FROM agg
    UNION ALL SELECT 'icu_los_median', icu_los_med, 'days', 9 FROM icu
    UNION ALL SELECT 'icu_los_p25', icu_los_p25, 'days', 10 FROM icu
    UNION ALL SELECT 'icu_los_p75', icu_los_p75, 'days', 11 FROM icu
    UNION ALL SELECT 'icu_los_mean', icu_los_mean, 'days', 12 FROM icu
)

SELECT metric, round(value, 2) AS value, unit
FROM metrics
ORDER BY sort
