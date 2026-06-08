-- cdm_person_all: all persons (pre event-less filter); person_id authority keyed by subject_id.
WITH subject_ethnicity AS (
    SELECT DISTINCT
        subject_id,
        FIRST_VALUE(ethnicity) OVER (
            PARTITION BY subject_id ORDER BY admittime ASC
        ) AS ethnicity_first
    FROM {{ ref('src_admissions') }}
)
SELECT
    {{ mimic_sk('patients', 'p.subject_id') }}  AS person_id,
    CASE WHEN p.gender = 'F' THEN 8532
         WHEN p.gender = 'M' THEN 8507
         ELSE 0 END                     AS gender_concept_id,
    p.anchor_year - p.anchor_age        AS year_of_birth,
    CAST(NULL AS INTEGER)               AS month_of_birth,
    CAST(NULL AS INTEGER)               AS day_of_birth,
    CAST(NULL AS TIMESTAMP)             AS birth_datetime,
    COALESCE(CASE WHEN map_eth.target_vocabulary_id <> 'Ethnicity'
                  THEN map_eth.target_concept_id END, 0)    AS race_concept_id,
    COALESCE(CASE WHEN map_eth.target_vocabulary_id = 'Ethnicity'
                  THEN map_eth.target_concept_id END, 0)    AS ethnicity_concept_id,
    CAST(NULL AS BIGINT)                AS location_id,
    CAST(NULL AS BIGINT)                AS provider_id,
    CAST(NULL AS BIGINT)                AS care_site_id,
    CAST(p.subject_id AS VARCHAR)       AS person_source_value,
    p.gender                           AS gender_source_value,
    0                                  AS gender_source_concept_id,
    CASE WHEN map_eth.target_vocabulary_id <> 'Ethnicity'
         THEN eth.ethnicity_first END  AS race_source_value,
    COALESCE(CASE WHEN map_eth.target_vocabulary_id <> 'Ethnicity'
                  THEN map_eth.source_concept_id END, 0)    AS race_source_concept_id,
    CASE WHEN map_eth.target_vocabulary_id = 'Ethnicity'
         THEN eth.ethnicity_first END  AS ethnicity_source_value,
    COALESCE(CASE WHEN map_eth.target_vocabulary_id = 'Ethnicity'
                  THEN map_eth.source_concept_id END, 0)    AS ethnicity_source_concept_id
FROM {{ ref('src_patients') }} p
LEFT JOIN subject_ethnicity eth
    ON p.subject_id = eth.subject_id
LEFT JOIN {{ ref('lk_pat_ethnicity_concept') }} map_eth
    ON eth.ethnicity_first = map_eth.source_code
