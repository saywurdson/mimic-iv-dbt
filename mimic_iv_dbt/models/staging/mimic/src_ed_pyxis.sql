-- snapshot: ed.pyxis (ED Pyxis dispensing). GSN only (no NDC) -> mapped via the gsn_to_rxnorm seed.
SELECT
    subject_id::BIGINT          AS subject_id,
    stay_id::BIGINT             AS stay_id,
    charttime::TIMESTAMP        AS charttime,
    name                        AS name,
    gsn                         AS gsn,
    'pyxis'                     AS load_table_id
FROM {{ read_mimic4('pyxis', 'ed', varchar_cols=['gsn']) }}
