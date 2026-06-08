-- cdm_observation: observation_mapped + procedure + diagnoses + specimen + chartevents, domain='Observation'.
WITH rule_obs AS (
    SELECT
        CAST(NULL AS BIGINT)                        AS observation_id_src,  -- keyed below
        per.person_id,
        src.target_concept_id                       AS observation_concept_id,
        CAST(src.start_datetime AS DATE)            AS observation_date,
        src.start_datetime                          AS observation_datetime,
        src.type_concept_id                         AS observation_type_concept_id,
        CAST(NULL AS DOUBLE)                        AS value_as_number,
        src.value_as_string                         AS value_as_string,
        CASE WHEN src.value_as_string IS NOT NULL THEN COALESCE(src.value_as_concept_id, 0) END AS value_as_concept_id,
        CAST(NULL AS BIGINT)                        AS unit_concept_id,
        vis.visit_occurrence_id,
        src.source_code                             AS observation_source_value,
        src.source_concept_id                       AS observation_source_concept_id,
        CAST(NULL AS VARCHAR)                       AS unit_source_value,
        'observation.admissions'                    AS unit_id
    FROM {{ ref('lk_observation_mapped') }} src
    INNER JOIN {{ ref('cdm_person_all') }} per ON CAST(src.subject_id AS VARCHAR) = per.person_source_value
    LEFT JOIN {{ ref('visit_occurrence') }} vis
        ON vis.visit_source_value = CAST(src.subject_id AS VARCHAR) || '|' || CAST(src.hadm_id AS VARCHAR)
    WHERE src.target_domain_id = 'Observation'
),
rule_proc AS (
    SELECT
        CAST(NULL AS BIGINT)                        AS observation_id_src,
        per.person_id,
        src.target_concept_id                       AS observation_concept_id,
        CAST(src.start_datetime AS DATE)            AS observation_date,
        src.start_datetime                          AS observation_datetime,
        src.type_concept_id                         AS observation_type_concept_id,
        CAST(NULL AS DOUBLE)                        AS value_as_number,
        CAST(NULL AS VARCHAR)                       AS value_as_string,
        CAST(NULL AS BIGINT)                        AS value_as_concept_id,
        CAST(NULL AS BIGINT)                        AS unit_concept_id,
        vis.visit_occurrence_id,
        src.source_code                             AS observation_source_value,
        src.source_concept_id                       AS observation_source_concept_id,
        CAST(NULL AS VARCHAR)                       AS unit_source_value,
        'observation.procedure'                     AS unit_id
    FROM {{ ref('lk_procedure_mapped') }} src
    INNER JOIN {{ ref('cdm_person_all') }} per ON CAST(src.subject_id AS VARCHAR) = per.person_source_value
    LEFT JOIN {{ ref('visit_occurrence') }} vis
        ON vis.visit_source_value = CAST(src.subject_id AS VARCHAR) || '|' || CAST(src.hadm_id AS VARCHAR)
    WHERE src.target_domain_id = 'Observation'
),
rule_diag AS (
    SELECT
        CAST(NULL AS BIGINT)                        AS observation_id_src,
        per.person_id,
        src.target_concept_id                       AS observation_concept_id,
        CAST(src.start_datetime AS DATE)            AS observation_date,
        src.start_datetime                          AS observation_datetime,
        src.type_concept_id                         AS observation_type_concept_id,
        CAST(NULL AS DOUBLE)                        AS value_as_number,
        CAST(NULL AS VARCHAR)                       AS value_as_string,
        CAST(NULL AS BIGINT)                        AS value_as_concept_id,
        CAST(NULL AS BIGINT)                        AS unit_concept_id,
        vis.visit_occurrence_id,
        src.source_code                             AS observation_source_value,
        COALESCE(src.source_concept_id, 0)          AS observation_source_concept_id,
        CAST(NULL AS VARCHAR)                       AS unit_source_value,
        'observation.diagnoses_icd'                 AS unit_id
    FROM {{ ref('lk_diagnoses_icd_mapped') }} src
    INNER JOIN {{ ref('cdm_person_all') }} per ON CAST(src.subject_id AS VARCHAR) = per.person_source_value
    LEFT JOIN {{ ref('visit_occurrence') }} vis
        ON vis.visit_source_value = CAST(src.subject_id AS VARCHAR) || '|' || CAST(src.hadm_id AS VARCHAR)
    WHERE src.target_domain_id = 'Observation'
),
rule_spec AS (
    SELECT
        CAST(NULL AS BIGINT)                        AS observation_id_src,
        per.person_id,
        src.target_concept_id                       AS observation_concept_id,
        CAST(src.start_datetime AS DATE)            AS observation_date,
        src.start_datetime                          AS observation_datetime,
        src.type_concept_id                         AS observation_type_concept_id,
        CAST(NULL AS DOUBLE)                        AS value_as_number,
        CAST(NULL AS VARCHAR)                       AS value_as_string,
        CAST(NULL AS BIGINT)                        AS value_as_concept_id,
        CAST(NULL AS BIGINT)                        AS unit_concept_id,
        vis.visit_occurrence_id,
        src.source_code                             AS observation_source_value,
        src.source_concept_id                       AS observation_source_concept_id,
        CAST(NULL AS VARCHAR)                       AS unit_source_value,
        'observation.specimen'                      AS unit_id
    FROM {{ ref('lk_specimen_mapped') }} src
    INNER JOIN {{ ref('cdm_person_all') }} per ON CAST(src.subject_id AS VARCHAR) = per.person_source_value
    LEFT JOIN {{ ref('visit_occurrence') }} vis
        ON vis.visit_source_value = CAST(src.subject_id AS VARCHAR) || '|' ||
            COALESCE(CAST(src.hadm_id AS VARCHAR), CAST(src.date_id AS VARCHAR))
    WHERE src.target_domain_id = 'Observation'
),
non_ce AS (
    SELECT * FROM rule_obs
    UNION ALL SELECT * FROM rule_proc
    UNION ALL SELECT * FROM rule_diag
    UNION ALL SELECT * FROM rule_spec
),
non_ce_keyed AS (
    SELECT
        {{ mimic_sk('observation', 'person_id, observation_concept_id, observation_datetime, observation_source_value, unit_id') }} AS observation_id,
        *
    FROM non_ce
),
-- chartevents observations reuse measurement_id (already unique).
ce AS (
    SELECT
        src.measurement_id                          AS observation_id,
        CAST(NULL AS BIGINT)                        AS observation_id_src,
        per.person_id,
        src.target_concept_id                       AS observation_concept_id,
        CAST(src.start_datetime AS DATE)            AS observation_date,
        src.start_datetime                          AS observation_datetime,
        src.type_concept_id                         AS observation_type_concept_id,
        src.value_as_number                         AS value_as_number,
        src.value_source_value                      AS value_as_string,
        CASE WHEN src.value_source_value IS NOT NULL THEN COALESCE(src.value_as_concept_id, 0) END AS value_as_concept_id,
        src.unit_concept_id                         AS unit_concept_id,
        vis.visit_occurrence_id,
        src.source_code                             AS observation_source_value,
        src.source_concept_id                       AS observation_source_concept_id,
        src.unit_source_value                       AS unit_source_value,
        'observation.chartevents'                   AS unit_id
    FROM {{ ref('lk_chartevents_mapped') }} src
    INNER JOIN {{ ref('cdm_person_all') }} per ON CAST(src.subject_id AS VARCHAR) = per.person_source_value
    LEFT JOIN {{ ref('visit_occurrence') }} vis
        ON vis.visit_source_value = CAST(src.subject_id AS VARCHAR) || '|' || CAST(src.hadm_id AS VARCHAR)
    WHERE src.target_domain_id = 'Observation'
)
SELECT
    observation_id, person_id, observation_concept_id, observation_date, observation_datetime,
    observation_type_concept_id, value_as_number, value_as_string, value_as_concept_id,
    CAST(NULL AS BIGINT) AS qualifier_concept_id, unit_concept_id,
    CAST(NULL AS BIGINT) AS provider_id, visit_occurrence_id, CAST(NULL AS BIGINT) AS visit_detail_id,
    observation_source_value, observation_source_concept_id, unit_source_value,
    CAST(NULL AS VARCHAR) AS qualifier_source_value,
    CAST(NULL AS VARCHAR) AS value_source_value,
    CAST(NULL AS BIGINT) AS observation_event_id,
    CAST(NULL AS BIGINT) AS obs_event_field_concept_id
FROM non_ce_keyed
UNION ALL
SELECT
    observation_id, person_id, observation_concept_id, observation_date, observation_datetime,
    observation_type_concept_id, value_as_number, value_as_string, value_as_concept_id,
    CAST(NULL AS BIGINT) AS qualifier_concept_id, unit_concept_id,
    CAST(NULL AS BIGINT) AS provider_id, visit_occurrence_id, CAST(NULL AS BIGINT) AS visit_detail_id,
    observation_source_value, observation_source_concept_id, unit_source_value,
    CAST(NULL AS VARCHAR) AS qualifier_source_value,
    CAST(NULL AS VARCHAR) AS value_source_value,
    CAST(NULL AS BIGINT) AS observation_event_id,
    CAST(NULL AS BIGINT) AS obs_event_field_concept_id
FROM ce
