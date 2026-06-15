-- snapshot: ed.medrecon (home/reconciled meds recorded at ED arrival). Has NDC and GSN.
SELECT
    subject_id::BIGINT          AS subject_id,
    stay_id::BIGINT             AS stay_id,
    charttime::TIMESTAMP        AS charttime,
    name                        AS name,
    gsn                         AS gsn,
    ndc                         AS ndc,
    etccode                     AS etccode,
    etcdescription              AS etcdescription,
    'medrecon'                  AS load_table_id
FROM {{ read_mimic4('medrecon', 'ed', varchar_cols=['gsn', 'ndc', 'etccode']) }}
