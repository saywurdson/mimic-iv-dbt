-- snapshot: hosp.hcpcsevents
SELECT
    hadm_id::BIGINT         AS hadm_id,
    subject_id::BIGINT      AS subject_id,
    hcpcs_cd                AS hcpcs_cd,
    seq_num::INTEGER        AS seq_num,
    short_description       AS short_description,
    'hcpcsevents'          AS load_table_id
FROM {{ read_mimic4('hcpcsevents', 'hosp', varchar_cols=['hcpcs_cd']) }}
