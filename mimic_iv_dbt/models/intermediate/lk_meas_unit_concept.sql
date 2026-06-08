-- lk_meas_unit_concept: unit source code -> concept (UCUM + custom mimiciv units).
-- De-duped per concept_code; non-standard targets allowed.
WITH tmp AS (
    SELECT
        concept_code,
        vocabulary_id,
        domain_id,
        concept_id,
        ROW_NUMBER() OVER (PARTITION BY concept_code ORDER BY UPPER(vocabulary_id)) AS row_num
    FROM {{ ref('voc_concept') }}
    WHERE vocabulary_id IN ('UCUM', 'mimiciv_meas_unit', 'mimiciv_meas_wf_unit')
      AND domain_id = 'Unit'
)
SELECT
    vc.concept_code         AS source_code,
    vc.vocabulary_id        AS source_vocabulary_id,
    vc.domain_id            AS source_domain_id,
    vc.concept_id           AS source_concept_id,
    vc2.domain_id           AS target_domain_id,
    vc2.concept_id          AS target_concept_id
FROM tmp vc
LEFT JOIN {{ ref('voc_concept_relationship') }} vcr
    ON  vc.concept_id = vcr.concept_id_1
    AND vcr.relationship_id = 'Maps to'
LEFT JOIN {{ ref('voc_concept') }} vc2
    ON  vc2.concept_id = vcr.concept_id_2
    AND vc2.invalid_reason IS NULL
WHERE vc.row_num = 1
