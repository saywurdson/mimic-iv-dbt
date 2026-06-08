-- procedures unioned from hcpcsevents, procedures_icd, procedureevents, datetimeevents.
WITH hcpcs AS (
    SELECT
        src.subject_id, src.hadm_id, adm.dischtime AS start_datetime,
        32821 AS type_concept_id,
        CAST(1 AS DOUBLE) AS quantity,
        CAST(NULL AS BIGINT) AS itemid,
        src.hcpcs_cd AS source_code,
        CAST(NULL AS VARCHAR) AS source_label,
        lc.source_vocabulary_id, lc.source_domain_id,
        COALESCE(lc.source_concept_id, 0) AS source_concept_id,
        COALESCE(lc.target_domain_id, 'Procedure') AS target_domain_id,
        COALESCE(lc.target_concept_id, 0) AS target_concept_id,
        'proc.hcpcsevents' AS unit_id, src.load_table_id
    FROM {{ ref('src_hcpcsevents') }} src
    INNER JOIN {{ ref('src_admissions') }} adm ON src.hadm_id = adm.hadm_id
    LEFT JOIN {{ ref('lk_hcpcs_concept') }} lc ON src.hcpcs_cd = lc.source_code
),
icd AS (
    SELECT
        src.subject_id, src.hadm_id, adm.dischtime AS start_datetime,
        32821 AS type_concept_id,
        CAST(1 AS DOUBLE) AS quantity,
        CAST(NULL AS BIGINT) AS itemid,
        REPLACE(src.icd_code, '.', '') AS source_code,
        CAST(NULL AS VARCHAR) AS source_label,
        CASE WHEN src.icd_version = 9 THEN 'ICD9Proc'
             WHEN src.icd_version = 10 THEN 'ICD10PCS' ELSE 'Unknown' END AS source_vocabulary_id,
        lc.source_domain_id,
        COALESCE(lc.source_concept_id, 0) AS source_concept_id,
        COALESCE(lc.target_domain_id, 'Procedure') AS target_domain_id,
        COALESCE(lc.target_concept_id, 0) AS target_concept_id,
        'proc.procedures_icd' AS unit_id, src.load_table_id
    FROM {{ ref('src_procedures_icd') }} src
    INNER JOIN {{ ref('src_admissions') }} adm ON src.hadm_id = adm.hadm_id
    LEFT JOIN {{ ref('lk_icd_proc_concept') }} lc
        ON REPLACE(src.icd_code, '.', '') = lc.source_code
        AND (CASE WHEN src.icd_version = 9 THEN 'ICD9Proc' WHEN src.icd_version = 10 THEN 'ICD10PCS' END) = lc.source_vocabulary_id
),
procevents AS (
    SELECT
        src.subject_id, src.hadm_id, src.starttime AS start_datetime,
        32833 AS type_concept_id,
        src.value AS quantity,
        lc.itemid AS itemid,
        CAST(src.itemid AS VARCHAR) AS source_code,
        lc.source_label,
        lc.source_vocabulary_id, lc.source_domain_id,
        COALESCE(lc.source_concept_id, 0) AS source_concept_id,
        COALESCE(lc.target_domain_id, 'Procedure') AS target_domain_id,
        COALESCE(lc.target_concept_id, 0) AS target_concept_id,
        'proc.procedureevents' AS unit_id, src.load_table_id
    FROM {{ ref('src_procedureevents') }} src
    LEFT JOIN {{ ref('lk_itemid_concept') }} lc ON src.itemid = lc.itemid
    WHERE src.cancelreason = 0
),
dtevents AS (
    SELECT
        src.subject_id, src.hadm_id, src.value AS start_datetime,
        32833 AS type_concept_id,
        CAST(1 AS DOUBLE) AS quantity,
        lc.itemid AS itemid,
        CAST(src.itemid AS VARCHAR) AS source_code,
        lc.source_label,
        lc.source_vocabulary_id, lc.source_domain_id,
        COALESCE(lc.source_concept_id, 0) AS source_concept_id,
        COALESCE(lc.target_domain_id, 'Procedure') AS target_domain_id,
        COALESCE(lc.target_concept_id, 0) AS target_concept_id,
        'proc.datetimeevents' AS unit_id, src.load_table_id
    FROM {{ ref('src_datetimeevents') }} src
    INNER JOIN {{ ref('src_patients') }} pat ON pat.subject_id = src.subject_id
    LEFT JOIN {{ ref('lk_itemid_concept') }} lc ON src.itemid = lc.itemid
    WHERE EXTRACT(YEAR FROM src.value) >= pat.anchor_year - pat.anchor_age
)
SELECT * FROM hcpcs
UNION ALL SELECT * FROM icd
UNION ALL SELECT * FROM procevents
UNION ALL SELECT * FROM dtevents
