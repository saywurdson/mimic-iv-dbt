-- snapshot: note.radiology (MIMIC-IV-Note radiology reports; note_type 'RR'/'AR')
SELECT
    note_id                     AS note_id,
    subject_id::BIGINT          AS subject_id,
    TRY_CAST(hadm_id AS BIGINT) AS hadm_id,
    note_type                   AS note_type,
    charttime::TIMESTAMP        AS charttime,
    text                        AS text,
    'radiology'                 AS load_table_id
FROM {{ read_mimic4('radiology', 'note', varchar_cols=['note_id','note_type','hadm_id','text']) }}
