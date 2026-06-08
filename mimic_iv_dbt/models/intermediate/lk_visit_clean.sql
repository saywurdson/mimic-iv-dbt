-- visit_occurrence authority: admissions visits + synthesized no-hadm single-day visits.
WITH unioned AS (
    SELECT
        subject_id,
        hadm_id,
        CAST(NULL AS DATE)                          AS date_id,
        start_datetime,
        end_datetime,
        admission_type,
        admission_location,
        discharge_location,
        CAST(subject_id AS VARCHAR) || '|' || CAST(hadm_id AS VARCHAR) AS source_value,
        unit_id,
        load_table_id
    FROM {{ ref('lk_admissions_clean') }}
    UNION ALL
    SELECT
        subject_id,
        CAST(NULL AS BIGINT)                        AS hadm_id,
        date_id,
        start_datetime,
        end_datetime,
        admission_type,
        admission_location,
        discharge_location,
        CAST(subject_id AS VARCHAR) || '|' || CAST(date_id AS VARCHAR) AS source_value,
        unit_id,
        load_table_id
    FROM {{ ref('lk_visit_no_hadm_dist') }}
)
SELECT
    {{ mimic_sk('visit_occurrence', 'source_value') }} AS visit_occurrence_id,
    *
FROM unioned
