-- cdm_device_exposure: drug_mapped + chartevents_mapped, domain='Device'.
WITH rule_drug AS (
    SELECT
        per.person_id,
        src.target_concept_id                       AS device_concept_id,
        CAST(src.start_datetime AS DATE)            AS device_exposure_start_date,
        src.start_datetime                          AS device_exposure_start_datetime,
        CAST(src.end_datetime AS DATE)              AS device_exposure_end_date,
        src.end_datetime                            AS device_exposure_end_datetime,
        src.type_concept_id                         AS device_type_concept_id,
        CAST(CASE WHEN ROUND(src.quantity) = src.quantity THEN src.quantity END AS BIGINT) AS quantity,
        vis.visit_occurrence_id,
        src.source_code                             AS device_source_value,
        src.source_concept_id                       AS device_source_concept_id,
        'device.drug'                               AS unit_id
    FROM {{ ref('lk_drug_mapped') }} src
    INNER JOIN {{ ref('cdm_person_all') }} per ON CAST(src.subject_id AS VARCHAR) = per.person_source_value
    LEFT JOIN {{ ref('visit_occurrence') }} vis
        ON vis.visit_source_value = CAST(src.subject_id AS VARCHAR) || '|' || CAST(src.hadm_id AS VARCHAR)
    WHERE src.target_domain_id = 'Device'
),
rule_ce AS (
    SELECT
        per.person_id,
        src.target_concept_id                       AS device_concept_id,
        CAST(src.start_datetime AS DATE)            AS device_exposure_start_date,
        src.start_datetime                          AS device_exposure_start_datetime,
        CAST(src.start_datetime AS DATE)            AS device_exposure_end_date,
        src.start_datetime                          AS device_exposure_end_datetime,
        src.type_concept_id                         AS device_type_concept_id,
        CAST(CASE WHEN ROUND(src.value_as_number) = src.value_as_number THEN src.value_as_number END AS BIGINT) AS quantity,
        vis.visit_occurrence_id,
        src.source_code                             AS device_source_value,
        src.source_concept_id                       AS device_source_concept_id,
        'device.chartevents'                        AS unit_id
    FROM {{ ref('lk_chartevents_mapped') }} src
    INNER JOIN {{ ref('cdm_person_all') }} per ON CAST(src.subject_id AS VARCHAR) = per.person_source_value
    LEFT JOIN {{ ref('visit_occurrence') }} vis
        ON vis.visit_source_value = CAST(src.subject_id AS VARCHAR) || '|' || CAST(src.hadm_id AS VARCHAR)
    WHERE src.target_domain_id = 'Device'
),
unioned AS (
    SELECT * FROM rule_drug
    UNION ALL SELECT * FROM rule_ce
)
SELECT
    {{ mimic_sk('device_exposure', 'person_id, device_concept_id, device_exposure_start_datetime, device_source_value, unit_id') }} AS device_exposure_id,
    person_id,
    device_concept_id,
    device_exposure_start_date,
    device_exposure_start_datetime,
    device_exposure_end_date,
    device_exposure_end_datetime,
    device_type_concept_id,
    CAST(NULL AS VARCHAR)   AS unique_device_id,
    CAST(NULL AS VARCHAR)   AS production_id,
    quantity,
    CAST(NULL AS BIGINT)    AS provider_id,
    visit_occurrence_id,
    CAST(NULL AS BIGINT)    AS visit_detail_id,
    device_source_value,
    device_source_concept_id,
    CAST(NULL AS BIGINT)    AS unit_concept_id,
    CAST(NULL AS VARCHAR)   AS unit_source_value,
    CAST(NULL AS BIGINT)    AS unit_source_concept_id
FROM unioned
