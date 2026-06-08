-- cdm_observation_period: one row per person spanning MIN/MAX dates across all event domains + death.
WITH spans AS (
    SELECT person_id, visit_start_date AS start_date, visit_end_date AS end_date FROM {{ ref('visit_occurrence') }}
    UNION ALL
    SELECT person_id, condition_start_date, condition_end_date FROM {{ ref('condition_occurrence') }}
    UNION ALL
    SELECT person_id, procedure_date, procedure_date FROM {{ ref('procedure_occurrence') }}
    UNION ALL
    SELECT person_id, drug_exposure_start_date, drug_exposure_end_date FROM {{ ref('drug_exposure') }}
    UNION ALL
    SELECT person_id, device_exposure_start_date, device_exposure_end_date FROM {{ ref('device_exposure') }}
    UNION ALL
    SELECT person_id, measurement_date, measurement_date FROM {{ ref('measurement') }}
    UNION ALL
    SELECT person_id, specimen_date, specimen_date FROM {{ ref('specimen') }}
    UNION ALL
    SELECT person_id, observation_date, observation_date FROM {{ ref('observation') }}
    UNION ALL
    SELECT person_id, death_date, death_date FROM {{ ref('death') }}
)
SELECT
    {{ mimic_sk('observation_period', 'person_id') }}   AS observation_period_id,
    person_id                                           AS person_id,
    MIN(start_date)                                     AS observation_period_start_date,
    MAX(end_date)                                       AS observation_period_end_date,
    32828                                               AS period_type_concept_id
FROM spans
GROUP BY person_id
