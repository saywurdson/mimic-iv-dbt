-- snapshot: note.discharge (MIMIC-IV-Note discharge summaries; note_type = 'DS')
SELECT
    note_id                     AS note_id,
    subject_id::BIGINT          AS subject_id,
    TRY_CAST(hadm_id AS BIGINT) AS hadm_id,
    note_type                   AS note_type,
    charttime::TIMESTAMP        AS charttime,
    text                        AS text,
    'discharge'                 AS load_table_id
FROM {{ read_mimic4('discharge', 'note', varchar_cols=['note_id','note_type','hadm_id','text']) }}
