-- snapshot: ed.edstays (MIMIC-IV-ED stays). stay_id = ED visit grain; hadm_id present iff admitted.
SELECT
    subject_id::BIGINT          AS subject_id,
    hadm_id::BIGINT             AS hadm_id,
    stay_id::BIGINT             AS stay_id,
    intime::TIMESTAMP           AS intime,
    outtime::TIMESTAMP          AS outtime,
    gender                      AS gender,
    race                        AS race,
    arrival_transport           AS arrival_transport,
    disposition                 AS disposition,
    'edstays'                   AS load_table_id
FROM {{ read_mimic4('edstays', 'ed') }}
