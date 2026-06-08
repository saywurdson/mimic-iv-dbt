-- synthesize one ambulatory single-day visit per subject+date for events lacking hadm_id.
WITH all_no_hadm AS (
    SELECT subject_id, CAST(start_datetime AS DATE) AS date_id, start_datetime
    FROM {{ ref('lk_meas_labevents_mapped') }} WHERE hadm_id IS NULL
    UNION ALL
    SELECT subject_id, CAST(start_datetime AS DATE) AS date_id, start_datetime
    FROM {{ ref('lk_specimen_mapped') }} WHERE hadm_id IS NULL
    UNION ALL
    SELECT subject_id, CAST(start_datetime AS DATE) AS date_id, start_datetime
    FROM {{ ref('lk_meas_organism_mapped') }} WHERE hadm_id IS NULL
    UNION ALL
    SELECT subject_id, CAST(start_datetime AS DATE) AS date_id, start_datetime
    FROM {{ ref('lk_meas_ab_mapped') }} WHERE hadm_id IS NULL
)
SELECT
    subject_id                                      AS subject_id,
    date_id                                         AS date_id,
    MIN(start_datetime)                             AS start_datetime,
    MAX(start_datetime)                             AS end_datetime,
    'AMBULATORY OBSERVATION'                        AS admission_type,
    CAST(NULL AS VARCHAR)                           AS admission_location,
    CAST(NULL AS VARCHAR)                           AS discharge_location,
    'no_hadm'                                       AS unit_id,
    'lk_visit_no_hadm_all'                          AS load_table_id
FROM all_no_hadm
GROUP BY subject_id, date_id
