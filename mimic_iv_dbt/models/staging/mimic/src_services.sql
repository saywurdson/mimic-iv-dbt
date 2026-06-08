-- snapshot: hosp.services. trace_id used by lk_services_duplicated dedup.
SELECT
    subject_id::BIGINT      AS subject_id,
    hadm_id::BIGINT         AS hadm_id,
    transfertime::TIMESTAMP AS transfertime,
    prev_service            AS prev_service,
    curr_service            AS curr_service,
    'services'             AS load_table_id,
    CAST(subject_id AS VARCHAR) || '|' || CAST(hadm_id AS VARCHAR) || '|' || CAST(transfertime AS VARCHAR) AS trace_id
FROM {{ read_mimic4('services', 'hosp') }}
