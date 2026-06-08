-- snapshot: icu.procedureevents. cancelreason removed in 2.0 -> 0 (not cancelled).
SELECT
    hadm_id::BIGINT         AS hadm_id,
    subject_id::BIGINT      AS subject_id,
    stay_id::BIGINT         AS stay_id,
    itemid::BIGINT          AS itemid,
    starttime::TIMESTAMP    AS starttime,
    value::DOUBLE           AS value,
    0::INTEGER              AS cancelreason,
    'procedureevents'      AS load_table_id
FROM {{ read_mimic4('procedureevents', 'icu') }}
