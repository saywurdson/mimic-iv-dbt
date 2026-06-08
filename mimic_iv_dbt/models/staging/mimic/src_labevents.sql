-- snapshot: hosp.labevents. trace_id = labevent_id (unique).
SELECT
    labevent_id::BIGINT     AS labevent_id,
    subject_id::BIGINT      AS subject_id,
    charttime::TIMESTAMP    AS charttime,
    hadm_id::BIGINT         AS hadm_id,
    itemid::BIGINT          AS itemid,
    valueuom                AS valueuom,
    value                   AS value,
    flag                    AS flag,
    ref_range_lower::DOUBLE AS ref_range_lower,
    ref_range_upper::DOUBLE AS ref_range_upper,
    'labevents'            AS load_table_id,
    CAST(labevent_id AS VARCHAR) AS trace_id
FROM {{ read_mimic4('labevents', 'hosp', varchar_cols=['value','flag','valueuom']) }}
