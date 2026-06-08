-- cdm_measurement: labevents + chartevents + micro organism + antibiotics + outputevents, domain='Measurement'.
WITH rule_lab AS (
    SELECT
        src.measurement_id,
        per.person_id,
        COALESCE(src.target_concept_id, 0)      AS measurement_concept_id,
        CAST(src.start_datetime AS DATE)        AS measurement_date,
        src.start_datetime                      AS measurement_datetime,
        32856                                   AS measurement_type_concept_id,
        src.operator_concept_id                 AS operator_concept_id,
        CAST(src.value_as_number AS DOUBLE)     AS value_as_number,
        CAST(NULL AS BIGINT)                    AS value_as_concept_id,
        src.unit_concept_id                     AS unit_concept_id,
        src.range_low                           AS range_low,
        src.range_high                          AS range_high,
        vis.visit_occurrence_id,
        src.source_code                         AS measurement_source_value,
        src.source_concept_id                   AS measurement_source_concept_id,
        src.unit_source_value                   AS unit_source_value,
        src.value_source_value                  AS value_source_value,
        'measurement.labevents'                 AS unit_id
    FROM {{ ref('lk_meas_labevents_mapped') }} src
    INNER JOIN {{ ref('cdm_person_all') }} per ON CAST(src.subject_id AS VARCHAR) = per.person_source_value
    LEFT JOIN {{ ref('visit_occurrence') }} vis
        ON vis.visit_source_value = CAST(src.subject_id AS VARCHAR) || '|' ||
            COALESCE(CAST(src.hadm_id AS VARCHAR), CAST(src.date_id AS VARCHAR))
    WHERE src.target_domain_id = 'Measurement'
),
rule_ce AS (
    SELECT
        src.measurement_id,
        per.person_id,
        COALESCE(src.target_concept_id, 0)      AS measurement_concept_id,
        CAST(src.start_datetime AS DATE)        AS measurement_date,
        src.start_datetime                      AS measurement_datetime,
        src.type_concept_id                     AS measurement_type_concept_id,
        CAST(NULL AS BIGINT)                    AS operator_concept_id,
        src.value_as_number                     AS value_as_number,
        src.value_as_concept_id                 AS value_as_concept_id,
        src.unit_concept_id                     AS unit_concept_id,
        CAST(NULL AS DOUBLE)                    AS range_low,
        CAST(NULL AS DOUBLE)                    AS range_high,
        vis.visit_occurrence_id,
        src.source_code                         AS measurement_source_value,
        src.source_concept_id                   AS measurement_source_concept_id,
        src.unit_source_value                   AS unit_source_value,
        src.value_source_value                  AS value_source_value,
        'measurement.chartevents'               AS unit_id
    FROM {{ ref('lk_chartevents_mapped') }} src
    INNER JOIN {{ ref('cdm_person_all') }} per ON CAST(src.subject_id AS VARCHAR) = per.person_source_value
    LEFT JOIN {{ ref('visit_occurrence') }} vis
        ON vis.visit_source_value = CAST(src.subject_id AS VARCHAR) || '|' || CAST(src.hadm_id AS VARCHAR)
    WHERE src.target_domain_id = 'Measurement'
),
rule_org AS (
    SELECT
        src.measurement_id,
        per.person_id,
        COALESCE(src.target_concept_id, 0)      AS measurement_concept_id,
        CAST(src.start_datetime AS DATE)        AS measurement_date,
        src.start_datetime                      AS measurement_datetime,
        src.type_concept_id                     AS measurement_type_concept_id,
        CAST(NULL AS BIGINT)                    AS operator_concept_id,
        CAST(NULL AS DOUBLE)                    AS value_as_number,
        COALESCE(src.value_as_concept_id, 0)    AS value_as_concept_id,
        CAST(NULL AS BIGINT)                    AS unit_concept_id,
        CAST(NULL AS DOUBLE)                    AS range_low,
        CAST(NULL AS DOUBLE)                    AS range_high,
        vis.visit_occurrence_id,
        src.source_code                         AS measurement_source_value,
        src.source_concept_id                   AS measurement_source_concept_id,
        CAST(NULL AS VARCHAR)                   AS unit_source_value,
        src.value_source_value                  AS value_source_value,
        'measurement.organism'                  AS unit_id
    FROM {{ ref('lk_meas_organism_mapped') }} src
    INNER JOIN {{ ref('cdm_person_all') }} per ON CAST(src.subject_id AS VARCHAR) = per.person_source_value
    LEFT JOIN {{ ref('visit_occurrence') }} vis
        ON vis.visit_source_value = CAST(src.subject_id AS VARCHAR) || '|' ||
            COALESCE(CAST(src.hadm_id AS VARCHAR), CAST(src.date_id AS VARCHAR))
    WHERE src.target_domain_id = 'Measurement'
),
rule_ab AS (
    SELECT
        src.measurement_id,
        per.person_id,
        COALESCE(src.target_concept_id, 0)      AS measurement_concept_id,
        CAST(src.start_datetime AS DATE)        AS measurement_date,
        src.start_datetime                      AS measurement_datetime,
        src.type_concept_id                     AS measurement_type_concept_id,
        src.operator_concept_id                 AS operator_concept_id,
        src.value_as_number                     AS value_as_number,
        COALESCE(src.value_as_concept_id, 0)    AS value_as_concept_id,
        CAST(NULL AS BIGINT)                    AS unit_concept_id,
        CAST(NULL AS DOUBLE)                    AS range_low,
        CAST(NULL AS DOUBLE)                    AS range_high,
        vis.visit_occurrence_id,
        src.source_code                         AS measurement_source_value,
        src.source_concept_id                   AS measurement_source_concept_id,
        CAST(NULL AS VARCHAR)                   AS unit_source_value,
        src.value_source_value                  AS value_source_value,
        'measurement.antibiotics'               AS unit_id
    FROM {{ ref('lk_meas_ab_mapped') }} src
    INNER JOIN {{ ref('cdm_person_all') }} per ON CAST(src.subject_id AS VARCHAR) = per.person_source_value
    LEFT JOIN {{ ref('visit_occurrence') }} vis
        ON vis.visit_source_value = CAST(src.subject_id AS VARCHAR) || '|' ||
            COALESCE(CAST(src.hadm_id AS VARCHAR), CAST(src.date_id AS VARCHAR))
    WHERE src.target_domain_id = 'Measurement'
),
rule_out AS (
    SELECT
        src.measurement_id,
        per.person_id,
        COALESCE(src.target_concept_id, 0)      AS measurement_concept_id,
        CAST(src.start_datetime AS DATE)        AS measurement_date,
        src.start_datetime                      AS measurement_datetime,
        src.type_concept_id                     AS measurement_type_concept_id,
        CAST(NULL AS BIGINT)                    AS operator_concept_id,
        src.value_as_number                     AS value_as_number,
        COALESCE(src.value_as_concept_id, 0)    AS value_as_concept_id,
        CAST(NULL AS BIGINT)                    AS unit_concept_id,
        CAST(NULL AS DOUBLE)                    AS range_low,
        CAST(NULL AS DOUBLE)                    AS range_high,
        vis.visit_occurrence_id,
        src.source_code                         AS measurement_source_value,
        src.source_concept_id                   AS measurement_source_concept_id,
        src.unit_source_value                   AS unit_source_value,
        src.value_source_value                  AS value_source_value,
        'measurement.outputevents'              AS unit_id
    FROM {{ ref('lk_outputevents_mapped') }} src
    INNER JOIN {{ ref('cdm_person_all') }} per ON CAST(src.subject_id AS VARCHAR) = per.person_source_value
    LEFT JOIN {{ ref('visit_occurrence') }} vis
        ON vis.visit_source_value = CAST(src.subject_id AS VARCHAR) || '|' || CAST(src.hadm_id AS VARCHAR)
)
SELECT
    measurement_id, person_id, measurement_concept_id, measurement_date, measurement_datetime,
    CAST(NULL AS VARCHAR) AS measurement_time, measurement_type_concept_id, operator_concept_id,
    value_as_number, value_as_concept_id, unit_concept_id, range_low, range_high,
    CAST(NULL AS BIGINT) AS provider_id, visit_occurrence_id, CAST(NULL AS BIGINT) AS visit_detail_id,
    measurement_source_value, measurement_source_concept_id, unit_source_value,
    CAST(NULL AS BIGINT) AS unit_source_concept_id, value_source_value,
    CAST(NULL AS BIGINT) AS measurement_event_id, CAST(NULL AS BIGINT) AS meas_event_field_concept_id
FROM (
    SELECT * FROM rule_lab
    UNION ALL SELECT * FROM rule_ce
    UNION ALL SELECT * FROM rule_org
    UNION ALL SELECT * FROM rule_ab
    UNION ALL SELECT * FROM rule_out
) m
