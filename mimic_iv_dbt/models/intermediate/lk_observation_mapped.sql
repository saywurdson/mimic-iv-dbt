-- observation mapped. value_as_concept from value_as_string 'Maps to' (drg/insurance).
WITH obs_concept AS (
    SELECT DISTINCT
        src.value_as_string         AS source_code,
        src.source_vocabulary_id    AS source_vocabulary_id,
        vc.concept_id               AS source_concept_id,
        vc2.concept_id              AS target_concept_id
    FROM {{ ref('lk_observation_clean') }} src
    LEFT JOIN {{ ref('voc_concept') }} vc
        ON src.value_as_string = vc.concept_code AND src.source_vocabulary_id = vc.vocabulary_id
    LEFT JOIN {{ ref('voc_concept_relationship') }} vcr
        ON vc.concept_id = vcr.concept_id_1 AND vcr.relationship_id = 'Maps to'
    LEFT JOIN {{ ref('voc_concept') }} vc2
        ON vc2.concept_id = vcr.concept_id_2 AND vc2.standard_concept = 'S' AND vc2.invalid_reason IS NULL
)
SELECT
    src.hadm_id                             AS hadm_id,
    src.subject_id                          AS subject_id,
    COALESCE(src.target_concept_id, 0)      AS target_concept_id,
    src.start_datetime                      AS start_datetime,
    32817                                   AS type_concept_id,
    src.source_code                         AS source_code,
    0                                       AS source_concept_id,
    src.value_as_string                     AS value_as_string,
    lc.target_concept_id                    AS value_as_concept_id,
    'Observation'                           AS target_domain_id,
    src.unit_id,
    src.load_table_id
FROM {{ ref('lk_observation_clean') }} src
LEFT JOIN obs_concept lc
    ON src.value_as_string = lc.source_code AND src.source_vocabulary_id = lc.source_vocabulary_id
