-- snapshot: hosp.diagnoses_icd (icd_code forced VARCHAR)
SELECT
    subject_id::BIGINT      AS subject_id,
    hadm_id::BIGINT         AS hadm_id,
    seq_num::INTEGER        AS seq_num,
    icd_code                AS icd_code,
    icd_version::INTEGER    AS icd_version,
    'diagnoses_icd'        AS load_table_id
FROM {{ read_mimic4('diagnoses_icd', 'hosp', varchar_cols=['icd_code']) }}
