{{ config(materialized='table') }}

/* Single-row headline counts for the MIMIC-IV-ED (Emergency Department) cohort,
   on the ED-stay grain (one row per ed.edstays / lk_ed_visit). An ED stay carries
   a hadm_id only when an inpatient admission followed it, so the share of ED stays
   with a hadm_id is the ED -> inpatient admission rate. ED length of stay is in
   hours (the ED visit is short relative to a hospital stay); only non-negative
   durations contribute to the median. Dates are de-identified (shifted per
   patient), so intervals are exact while calendar dates are not. */

WITH ed AS (
    SELECT
        subject_id,
        hadm_id,
        visit_start_datetime,
        visit_end_datetime
    FROM {{ ref('lk_ed_visit') }}
)

SELECT
    count(*)                                                        AS n_ed_visits,
    count(DISTINCT subject_id)                                      AS n_ed_patients,
    count(*) FILTER (WHERE hadm_id IS NOT NULL)                     AS n_ed_to_inpatient,
    round(100.0 * count(*) FILTER (WHERE hadm_id IS NOT NULL)
          / nullif(count(*), 0), 1)                                 AS ed_to_inpatient_pct,
    round(median(CASE WHEN visit_end_datetime >= visit_start_datetime
                      THEN date_diff('minute', visit_start_datetime, visit_end_datetime) / 60.0
                 END), 1)                                           AS ed_los_hours_median
FROM ed
