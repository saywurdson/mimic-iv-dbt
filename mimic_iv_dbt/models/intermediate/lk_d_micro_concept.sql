-- lk_d_micro_concept: micro codes (d_micro itemids + resistance interpretations) -> concept.
WITH d_micro_clean AS (
    SELECT
        dm.itemid                                       AS itemid,
        CAST(dm.itemid AS VARCHAR)                      AS source_code,
        dm.label                                        AS source_label,
        CONCAT('mimiciv_micro_', LOWER(dm.category))    AS source_vocabulary_id
    FROM {{ ref('src_d_micro') }} dm
    UNION ALL
    SELECT DISTINCT
        CAST(NULL AS BIGINT)                            AS itemid,
        src.interpretation                              AS source_code,
        src.interpretation                              AS source_label,
        'mimiciv_micro_resistance'                      AS source_vocabulary_id
    FROM {{ ref('lk_meas_ab_clean') }} src
    WHERE src.interpretation IS NOT NULL
)
SELECT
    dm.itemid                   AS itemid,
    dm.source_code              AS source_code,
    dm.source_label             AS source_label,
    dm.source_vocabulary_id     AS source_vocabulary_id,
    vc.domain_id                AS source_domain_id,
    vc.concept_id               AS source_concept_id,
    vc.concept_name             AS source_concept_name,
    vc2.vocabulary_id           AS target_vocabulary_id,
    vc2.domain_id               AS target_domain_id,
    vc2.concept_id              AS target_concept_id,
    vc2.concept_name            AS target_concept_name,
    vc2.standard_concept        AS target_standard_concept
FROM d_micro_clean dm
LEFT JOIN {{ ref('voc_concept') }} vc
    ON  dm.source_code = vc.concept_code
    AND vc.vocabulary_id = dm.source_vocabulary_id
LEFT JOIN {{ ref('voc_concept_relationship') }} vcr
    ON  vc.concept_id = vcr.concept_id_1
    AND vcr.relationship_id = 'Maps to'
LEFT JOIN {{ ref('voc_concept') }} vc2
    ON  vc2.concept_id = vcr.concept_id_2
    AND vc2.standard_concept = 'S'
    AND vc2.invalid_reason IS NULL
