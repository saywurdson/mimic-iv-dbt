-- snapshot: ed.triage (one arrival-triage record per ED stay: vitals + acuity + chief complaint).
SELECT
    subject_id::BIGINT          AS subject_id,
    stay_id::BIGINT             AS stay_id,
    temperature                 AS temperature,
    heartrate                   AS heartrate,
    resprate                    AS resprate,
    o2sat                       AS o2sat,
    sbp                         AS sbp,
    dbp                         AS dbp,
    pain                        AS pain,
    acuity                      AS acuity,
    chiefcomplaint              AS chiefcomplaint,
    'triage'                    AS load_table_id
FROM {{ read_mimic4('triage', 'ed', varchar_cols=['pain', 'chiefcomplaint']) }}
