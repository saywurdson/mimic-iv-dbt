-- snapshot: hosp.admissions (race AS ethnicity per MIMIC-IV 2.0)
SELECT
    hadm_id::BIGINT             AS hadm_id,
    subject_id::BIGINT          AS subject_id,
    admittime::TIMESTAMP        AS admittime,
    dischtime::TIMESTAMP        AS dischtime,
    deathtime::TIMESTAMP        AS deathtime,
    admission_type              AS admission_type,
    admission_location          AS admission_location,
    discharge_location          AS discharge_location,
    race                        AS ethnicity,
    edregtime::TIMESTAMP        AS edregtime,
    insurance                   AS insurance,
    marital_status              AS marital_status,
    language                    AS language,
    'admissions'               AS load_table_id
FROM {{ read_mimic4('admissions', 'hosp') }}
