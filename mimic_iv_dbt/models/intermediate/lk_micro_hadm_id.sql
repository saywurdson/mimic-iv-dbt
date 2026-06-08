-- backfill missing hadm_id for micro events by datetime overlap.
SELECT
    src.trace_id_ab                     AS event_trace_id,
    adm.hadm_id                         AS hadm_id,
    ROW_NUMBER() OVER (PARTITION BY src.trace_id_ab ORDER BY adm.start_datetime) AS row_num
FROM {{ ref('lk_micro_cross_ref') }} src
INNER JOIN {{ ref('lk_admissions_clean') }} adm
    ON  adm.subject_id = src.subject_id
    AND src.start_datetime BETWEEN adm.start_datetime AND adm.end_datetime
WHERE src.hadm_id IS NULL
