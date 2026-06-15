-- snapshot: ed.diagnosis (MIMIC-IV-ED diagnoses; ICD-9/10 per ED stay).
SELECT
    subject_id::BIGINT          AS subject_id,
    stay_id::BIGINT             AS stay_id,
    seq_num::BIGINT             AS seq_num,
    icd_code                    AS icd_code,
    icd_version::BIGINT         AS icd_version,
    icd_title                   AS icd_title,
    'diagnosis'                 AS load_table_id
FROM {{ read_mimic4('diagnosis', 'ed', varchar_cols=['icd_code']) }}
