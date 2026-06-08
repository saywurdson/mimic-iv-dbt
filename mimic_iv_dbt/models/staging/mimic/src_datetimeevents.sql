-- snapshot: icu.datetimeevents. value is a datetime string.
SELECT
    subject_id::BIGINT      AS subject_id,
    hadm_id::BIGINT         AS hadm_id,
    stay_id::BIGINT         AS stay_id,
    itemid::BIGINT          AS itemid,
    charttime::TIMESTAMP    AS charttime,
    value::TIMESTAMP        AS value,
    'datetimeevents'       AS load_table_id
FROM {{ read_mimic4('datetimeevents', 'icu') }}
