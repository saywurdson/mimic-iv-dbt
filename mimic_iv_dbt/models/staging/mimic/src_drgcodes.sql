-- snapshot: hosp.drgcodes
SELECT
    hadm_id::BIGINT         AS hadm_id,
    subject_id::BIGINT      AS subject_id,
    drg_type                AS drg_type,
    drg_code                AS drg_code,
    description             AS description,
    'drgcodes'             AS load_table_id
FROM {{ read_mimic4('drgcodes', 'hosp', varchar_cols=['drg_code']) }}
