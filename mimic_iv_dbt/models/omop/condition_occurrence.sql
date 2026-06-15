-- cdm_condition_occurrence: diagnoses_icd + chartevents (value, main), domain='Condition'.
WITH rule_diag AS (
    SELECT
        per.person_id,
        COALESCE(src.target_concept_id, 0)      AS condition_concept_id,
        CAST(src.start_datetime AS DATE)        AS condition_start_date,
        src.start_datetime                      AS condition_start_datetime,
        CAST(src.end_datetime AS DATE)          AS condition_end_date,
        src.end_datetime                        AS condition_end_datetime,
        src.type_concept_id                     AS condition_type_concept_id,
        vis.visit_occurrence_id,
        src.source_code                         AS condition_source_value,
        COALESCE(src.source_concept_id, 0)      AS condition_source_concept_id,
        'condition.diagnoses_icd'               AS unit_id
    FROM {{ ref('lk_diagnoses_icd_mapped') }} src
    INNER JOIN {{ ref('cdm_person_all') }} per ON CAST(src.subject_id AS VARCHAR) = per.person_source_value
    LEFT JOIN {{ ref('visit_occurrence') }} vis
        ON vis.visit_source_value = CAST(src.subject_id AS VARCHAR) || '|' || CAST(src.hadm_id AS VARCHAR)
    WHERE src.target_domain_id = 'Condition'
),
rule_ce_value AS (
    SELECT
        per.person_id,
        COALESCE(src.target_concept_id, 0)      AS condition_concept_id,
        CAST(src.start_datetime AS DATE)        AS condition_start_date,
        src.start_datetime                      AS condition_start_datetime,
        CAST(src.start_datetime AS DATE)        AS condition_end_date,
        src.start_datetime                      AS condition_end_datetime,
        src.type_concept_id                     AS condition_type_concept_id,
        vis.visit_occurrence_id,
        src.source_code                         AS condition_source_value,
        COALESCE(src.source_concept_id, 0)      AS condition_source_concept_id,
        'condition.chartevents_value'           AS unit_id
    FROM {{ ref('lk_chartevents_condition_mapped') }} src
    INNER JOIN {{ ref('cdm_person_all') }} per ON CAST(src.subject_id AS VARCHAR) = per.person_source_value
    LEFT JOIN {{ ref('visit_occurrence') }} vis
        ON vis.visit_source_value = CAST(src.subject_id AS VARCHAR) || '|' || CAST(src.hadm_id AS VARCHAR)
    WHERE src.target_domain_id = 'Condition'
),
rule_ce_main AS (
    SELECT
        per.person_id,
        COALESCE(src.target_concept_id, 0)      AS condition_concept_id,
        CAST(src.start_datetime AS DATE)        AS condition_start_date,
        src.start_datetime                      AS condition_start_datetime,
        CAST(src.start_datetime AS DATE)        AS condition_end_date,
        src.start_datetime                      AS condition_end_datetime,
        src.type_concept_id                     AS condition_type_concept_id,
        vis.visit_occurrence_id,
        src.source_code                         AS condition_source_value,
        COALESCE(src.source_concept_id, 0)      AS condition_source_concept_id,
        'condition.chartevents'                 AS unit_id
    FROM {{ ref('lk_chartevents_mapped') }} src
    INNER JOIN {{ ref('cdm_person_all') }} per ON CAST(src.subject_id AS VARCHAR) = per.person_source_value
    LEFT JOIN {{ ref('visit_occurrence') }} vis
        ON vis.visit_source_value = CAST(src.subject_id AS VARCHAR) || '|' || CAST(src.hadm_id AS VARCHAR)
    WHERE src.target_domain_id = 'Condition'
),
rule_ed_diag AS (
    SELECT
        per.person_id,
        COALESCE(src.target_concept_id, 0)      AS condition_concept_id,
        CAST(src.start_datetime AS DATE)        AS condition_start_date,
        src.start_datetime                      AS condition_start_datetime,
        CAST(src.end_datetime AS DATE)          AS condition_end_date,
        src.end_datetime                        AS condition_end_datetime,
        src.type_concept_id                     AS condition_type_concept_id,
        vis.visit_occurrence_id,
        src.source_code                         AS condition_source_value,
        COALESCE(src.source_concept_id, 0)      AS condition_source_concept_id,
        'condition.ed_diagnosis'                AS unit_id
    FROM {{ ref('lk_ed_diagnosis_mapped') }} src
    INNER JOIN {{ ref('cdm_person_all') }} per ON CAST(src.subject_id AS VARCHAR) = per.person_source_value
    LEFT JOIN {{ ref('lk_ed_visit') }} vis ON src.stay_id = vis.stay_id
    WHERE src.target_domain_id = 'Condition'
),
unioned AS (
    SELECT * FROM rule_diag
    UNION ALL SELECT * FROM rule_ce_value
    UNION ALL SELECT * FROM rule_ce_main
)
SELECT
    {{ mimic_sk('condition_occurrence', 'person_id, condition_concept_id, condition_start_datetime, condition_source_value, unit_id') }} AS condition_occurrence_id,
    person_id,
    condition_concept_id,
    condition_start_date,
    condition_start_datetime,
    CASE WHEN condition_end_date < condition_start_date THEN condition_start_date ELSE condition_end_date END AS condition_end_date,
    CASE WHEN condition_end_datetime < condition_start_datetime THEN condition_start_datetime ELSE condition_end_datetime END AS condition_end_datetime,
    condition_type_concept_id,
    CAST(NULL AS VARCHAR)   AS stop_reason,
    CAST(NULL AS BIGINT)    AS provider_id,
    visit_occurrence_id,
    CAST(NULL AS BIGINT)    AS visit_detail_id,
    condition_source_value,
    condition_source_concept_id,
    CAST(NULL AS VARCHAR)   AS condition_status_source_value,
    CAST(NULL AS BIGINT)    AS condition_status_concept_id
FROM unioned

UNION ALL

-- MIMIC-IV-ED diagnoses -> condition_occurrence. Own id band (ed_condition=28) so
-- existing condition_occurrence ids stay untouched; visit_occurrence_id from lk_ed_visit (band 27).
SELECT
    {{ mimic_sk('ed_condition', 'person_id, condition_concept_id, condition_start_datetime, condition_source_value, unit_id') }} AS condition_occurrence_id,
    person_id,
    condition_concept_id,
    condition_start_date,
    condition_start_datetime,
    CASE WHEN condition_end_date < condition_start_date THEN condition_start_date ELSE condition_end_date END AS condition_end_date,
    CASE WHEN condition_end_datetime < condition_start_datetime THEN condition_start_datetime ELSE condition_end_datetime END AS condition_end_datetime,
    condition_type_concept_id,
    CAST(NULL AS VARCHAR)   AS stop_reason,
    CAST(NULL AS BIGINT)    AS provider_id,
    visit_occurrence_id,
    CAST(NULL AS BIGINT)    AS visit_detail_id,
    condition_source_value,
    condition_source_concept_id,
    CAST(NULL AS VARCHAR)   AS condition_status_source_value,
    CAST(NULL AS BIGINT)    AS condition_status_concept_id
FROM rule_ed_diag
