-- snapshot: hosp.procedures_icd (icd_code forced VARCHAR)
SELECT
    subject_id::BIGINT      AS subject_id,
    hadm_id::BIGINT         AS hadm_id,
    icd_code                AS icd_code,
    icd_version::INTEGER    AS icd_version,
    'procedures_icd'       AS load_table_id
FROM {{ read_mimic4('procedures_icd', 'hosp', varchar_cols=['icd_code']) }}
