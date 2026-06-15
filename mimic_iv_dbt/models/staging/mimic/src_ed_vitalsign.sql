-- snapshot: ed.vitalsign (time-series ED vitals).
SELECT
    subject_id::BIGINT          AS subject_id,
    stay_id::BIGINT             AS stay_id,
    charttime::TIMESTAMP        AS charttime,
    temperature                 AS temperature,
    heartrate                   AS heartrate,
    resprate                    AS resprate,
    o2sat                       AS o2sat,
    sbp                         AS sbp,
    dbp                         AS dbp,
    rhythm                      AS rhythm,
    pain                        AS pain,
    'vitalsign'                 AS load_table_id
FROM {{ read_mimic4('vitalsign', 'ed', varchar_cols=['pain', 'rhythm']) }}
