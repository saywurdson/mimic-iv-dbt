-- cdm_procedure_occurrence: procedure + observation + specimen + chartevents mapped, domain='Procedure'.
WITH rule_proc AS (
    SELECT
        per.person_id,
        src.target_concept_id                       AS procedure_concept_id,
        CAST(src.start_datetime AS DATE)            AS procedure_date,
        src.start_datetime                          AS procedure_datetime,
        src.type_concept_id                         AS procedure_type_concept_id,
        CAST(src.quantity AS BIGINT)                AS quantity,
        vis.visit_occurrence_id,
        src.source_code                             AS procedure_source_value,
        src.source_concept_id                       AS procedure_source_concept_id,
        'procedure.' || src.unit_id                 AS unit_id
    FROM {{ ref('lk_procedure_mapped') }} src
    INNER JOIN {{ ref('cdm_person_all') }} per ON CAST(src.subject_id AS VARCHAR) = per.person_source_value
    LEFT JOIN {{ ref('visit_occurrence') }} vis
        ON vis.visit_source_value = CAST(src.subject_id AS VARCHAR) || '|' || CAST(src.hadm_id AS VARCHAR)
    WHERE src.target_domain_id = 'Procedure'
),
rule_obs AS (
    SELECT
        per.person_id,
        src.target_concept_id                       AS procedure_concept_id,
        CAST(src.start_datetime AS DATE)            AS procedure_date,
        src.start_datetime                          AS procedure_datetime,
        src.type_concept_id                         AS procedure_type_concept_id,
        CAST(NULL AS BIGINT)                        AS quantity,
        vis.visit_occurrence_id,
        src.source_code                             AS procedure_source_value,
        src.source_concept_id                       AS procedure_source_concept_id,
        'procedure.observation'                     AS unit_id
    FROM {{ ref('lk_observation_mapped') }} src
    INNER JOIN {{ ref('cdm_person_all') }} per ON CAST(src.subject_id AS VARCHAR) = per.person_source_value
    LEFT JOIN {{ ref('visit_occurrence') }} vis
        ON vis.visit_source_value = CAST(src.subject_id AS VARCHAR) || '|' || CAST(src.hadm_id AS VARCHAR)
    WHERE src.target_domain_id = 'Procedure'
),
rule_spec AS (
    SELECT
        per.person_id,
        src.target_concept_id                       AS procedure_concept_id,
        CAST(src.start_datetime AS DATE)            AS procedure_date,
        src.start_datetime                          AS procedure_datetime,
        src.type_concept_id                         AS procedure_type_concept_id,
        CAST(NULL AS BIGINT)                        AS quantity,
        vis.visit_occurrence_id,
        src.source_code                             AS procedure_source_value,
        src.source_concept_id                       AS procedure_source_concept_id,
        'procedure.specimen'                        AS unit_id
    FROM {{ ref('lk_specimen_mapped') }} src
    INNER JOIN {{ ref('cdm_person_all') }} per ON CAST(src.subject_id AS VARCHAR) = per.person_source_value
    LEFT JOIN {{ ref('visit_occurrence') }} vis
        ON vis.visit_source_value = CAST(src.subject_id AS VARCHAR) || '|' ||
            COALESCE(CAST(src.hadm_id AS VARCHAR), CAST(src.date_id AS VARCHAR))
    WHERE src.target_domain_id = 'Procedure'
),
rule_ce AS (
    SELECT
        per.person_id,
        src.target_concept_id                       AS procedure_concept_id,
        CAST(src.start_datetime AS DATE)            AS procedure_date,
        src.start_datetime                          AS procedure_datetime,
        src.type_concept_id                         AS procedure_type_concept_id,
        CAST(NULL AS BIGINT)                        AS quantity,
        vis.visit_occurrence_id,
        src.source_code                             AS procedure_source_value,
        src.source_concept_id                       AS procedure_source_concept_id,
        'procedure.chartevents'                     AS unit_id
    FROM {{ ref('lk_chartevents_mapped') }} src
    INNER JOIN {{ ref('cdm_person_all') }} per ON CAST(src.subject_id AS VARCHAR) = per.person_source_value
    LEFT JOIN {{ ref('visit_occurrence') }} vis
        ON vis.visit_source_value = CAST(src.subject_id AS VARCHAR) || '|' || CAST(src.hadm_id AS VARCHAR)
    WHERE src.target_domain_id = 'Procedure'
),
unioned AS (
    SELECT * FROM rule_proc
    UNION ALL SELECT * FROM rule_obs
    UNION ALL SELECT * FROM rule_spec
    UNION ALL SELECT * FROM rule_ce
)
SELECT
    {{ mimic_sk('procedure_occurrence', 'person_id, procedure_concept_id, procedure_datetime, procedure_source_value, unit_id') }} AS procedure_occurrence_id,
    person_id,
    procedure_concept_id,
    procedure_date,
    procedure_datetime,
    CAST(NULL AS DATE)      AS procedure_end_date,
    CAST(NULL AS TIMESTAMP) AS procedure_end_datetime,
    procedure_type_concept_id,
    0                       AS modifier_concept_id,
    quantity,
    CAST(NULL AS BIGINT)    AS provider_id,
    visit_occurrence_id,
    CAST(NULL AS BIGINT)    AS visit_detail_id,
    procedure_source_value,
    procedure_source_concept_id,
    CAST(NULL AS VARCHAR)   AS modifier_source_value
FROM unioned
