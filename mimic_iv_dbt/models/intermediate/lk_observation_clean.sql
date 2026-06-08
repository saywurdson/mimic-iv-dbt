-- observation source rows from admissions (insurance/marital/language) + drgcodes.
SELECT
    src.subject_id, src.hadm_id,
    'Insurance' AS source_code,
    46235654 AS target_concept_id,
    src.admittime AS start_datetime,
    src.insurance AS value_as_string,
    'mimiciv_obs_insurance' AS source_vocabulary_id,
    'admissions.insurance' AS unit_id, src.load_table_id
FROM {{ ref('src_admissions') }} src WHERE src.insurance IS NOT NULL
UNION ALL
SELECT
    src.subject_id, src.hadm_id,
    'Marital status' AS source_code,
    40766231 AS target_concept_id,
    src.admittime AS start_datetime,
    src.marital_status AS value_as_string,
    'mimiciv_obs_marital' AS source_vocabulary_id,
    'admissions.marital_status' AS unit_id, src.load_table_id
FROM {{ ref('src_admissions') }} src WHERE src.marital_status IS NOT NULL
UNION ALL
SELECT
    src.subject_id, src.hadm_id,
    'Language' AS source_code,
    40758030 AS target_concept_id,
    src.admittime AS start_datetime,
    src.language AS value_as_string,
    'mimiciv_obs_language' AS source_vocabulary_id,
    'admissions.language' AS unit_id, src.load_table_id
FROM {{ ref('src_admissions') }} src WHERE src.language IS NOT NULL
UNION ALL
SELECT
    src.subject_id, src.hadm_id,
    src.drg_code AS source_code,
    4296248 AS target_concept_id,
    COALESCE(adm.edregtime, adm.admittime) AS start_datetime,
    src.description AS value_as_string,
    'mimiciv_obs_drgcodes' AS source_vocabulary_id,
    'drgcodes.description' AS unit_id, src.load_table_id
FROM {{ ref('src_drgcodes') }} src
INNER JOIN {{ ref('src_admissions') }} adm ON src.hadm_id = adm.hadm_id
WHERE src.description IS NOT NULL
