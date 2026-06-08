-- snapshot: icu.outputevents
SELECT
    subject_id::BIGINT      AS subject_id,
    hadm_id::BIGINT         AS hadm_id,
    stay_id::BIGINT         AS stay_id,
    charttime::TIMESTAMP    AS charttime,
    storetime::TIMESTAMP    AS storetime,
    itemid::BIGINT          AS itemid,
    value::DOUBLE           AS value,
    valueuom                AS valueuom,
    'outputevents'         AS load_table_id
FROM {{ read_mimic4('outputevents', 'icu') }}
