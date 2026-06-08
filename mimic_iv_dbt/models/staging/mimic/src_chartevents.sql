-- snapshot: icu.chartevents (~313M rows; value forced VARCHAR)
SELECT
    subject_id::BIGINT      AS subject_id,
    hadm_id::BIGINT         AS hadm_id,
    stay_id::BIGINT         AS stay_id,
    itemid::BIGINT          AS itemid,
    charttime::TIMESTAMP    AS charttime,
    value                   AS value,
    valuenum::DOUBLE        AS valuenum,
    valueuom                AS valueuom,
    'chartevents'          AS load_table_id
FROM {{ read_mimic4('chartevents', 'icu', varchar_cols=['value','valueuom']) }}
