-- ICD9Proc/ICD10PCS (dots stripped) -> standard ('Maps to').
SELECT
    REPLACE(vc.concept_code, '.', '')   AS source_code,
    vc.vocabulary_id                    AS source_vocabulary_id,
    vc.domain_id                        AS source_domain_id,
    vc.concept_id                       AS source_concept_id,
    vc2.domain_id                       AS target_domain_id,
    vc2.concept_id                      AS target_concept_id
FROM {{ ref('voc_concept') }} vc
LEFT JOIN {{ ref('voc_concept_relationship') }} vcr
    ON vc.concept_id = vcr.concept_id_1 AND vcr.relationship_id = 'Maps to'
LEFT JOIN {{ ref('voc_concept') }} vc2
    ON vc2.concept_id = vcr.concept_id_2 AND vc2.standard_concept = 'S' AND vc2.invalid_reason IS NULL
WHERE vc.vocabulary_id IN ('ICD9Proc', 'ICD10PCS')
