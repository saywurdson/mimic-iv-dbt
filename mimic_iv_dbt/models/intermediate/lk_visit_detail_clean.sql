-- visit_detail rows from transfers (with hadm_id), ER admissions, and services.
WITH rule_transfers AS (
    SELECT
        src.subject_id, src.hadm_id, src.date_id,
        src.start_datetime,
        src.end_datetime,
        CAST(src.subject_id AS VARCHAR) || '|' ||
            COALESCE(CAST(src.hadm_id AS VARCHAR), CAST(src.date_id AS VARCHAR)) || '|' ||
            CAST(src.transfer_id AS VARCHAR)            AS source_value,
        src.current_location,
        'transfers'                                     AS unit_id,
        src.load_table_id
    FROM {{ ref('lk_transfers_clean') }} src
    WHERE src.hadm_id IS NOT NULL
),
rule_er AS (
    SELECT
        src.subject_id, src.hadm_id, CAST(src.start_datetime AS DATE) AS date_id,
        src.start_datetime,
        CAST(NULL AS TIMESTAMP)                         AS end_datetime,
        CAST(src.subject_id AS VARCHAR) || '|' || CAST(src.hadm_id AS VARCHAR) AS source_value,
        src.admission_type                              AS current_location,
        'admissions'                                    AS unit_id,
        src.load_table_id
    FROM {{ ref('lk_admissions_clean') }} src
    WHERE src.is_er_admission
),
rule_services AS (
    SELECT
        src.subject_id, src.hadm_id, CAST(src.start_datetime AS DATE) AS date_id,
        src.start_datetime,
        src.end_datetime,
        CAST(src.subject_id AS VARCHAR) || '|' || CAST(src.hadm_id AS VARCHAR) || '|' ||
            CAST(src.start_datetime AS VARCHAR)         AS source_value,
        src.curr_service                                AS current_location,
        'services'                                      AS unit_id,
        src.load_table_id
    FROM {{ ref('lk_services_clean') }} src
    WHERE src.prev_service = src.lag_service
),
unioned AS (
    SELECT * FROM rule_transfers
    UNION ALL SELECT * FROM rule_er
    UNION ALL SELECT * FROM rule_services
)
SELECT
    {{ mimic_sk('visit_detail', 'source_value, unit_id, current_location') }} AS visit_detail_id,
    *
FROM unioned
