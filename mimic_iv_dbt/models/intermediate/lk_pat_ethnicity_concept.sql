-- ethnicity/race source code -> standard concept (first admission per subject).
WITH subject_ethnicity AS (
    SELECT DISTINCT
        subject_id,
        FIRST_VALUE(ethnicity) OVER (
            PARTITION BY subject_id ORDER BY admittime ASC
        ) AS ethnicity_first
    FROM {{ ref('src_admissions') }}
)
SELECT DISTINCT
    src.ethnicity_first     AS source_code,
    vc.concept_id           AS source_concept_id,
    vc.vocabulary_id        AS source_vocabulary_id,
    vc1.concept_id          AS target_concept_id,
    vc1.vocabulary_id       AS target_vocabulary_id
FROM subject_ethnicity src
LEFT JOIN {{ ref('voc_concept') }} vc
    ON  UPPER(vc.concept_code) = UPPER(src.ethnicity_first)
    AND vc.domain_id IN ('Race', 'Ethnicity')
LEFT JOIN {{ ref('voc_concept_relationship') }} cr1
    ON  cr1.concept_id_1 = vc.concept_id
    AND cr1.relationship_id = 'Maps to'
LEFT JOIN {{ ref('voc_concept') }} vc1
    ON  cr1.concept_id_2 = vc1.concept_id
    AND vc1.invalid_reason IS NULL
    AND vc1.standard_concept = 'S'
