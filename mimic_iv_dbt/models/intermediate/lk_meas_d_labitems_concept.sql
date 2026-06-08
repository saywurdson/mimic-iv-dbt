-- lk_meas_d_labitems_concept: d_labitems -> concept.
-- loinc_code dropped in MIMIC-IV 2.0, so source = itemid via mimiciv_meas_lab_loinc crosswalk.
WITH dlab_clean AS (
    SELECT
        itemid,
        COALESCE(loinc_code, CAST(itemid AS VARCHAR))               AS source_code,
        loinc_code,
        CONCAT(label, '|', fluid, '|', category)                    AS source_label,
        CASE WHEN loinc_code IS NOT NULL THEN 'LOINC' ELSE 'mimiciv_meas_lab_loinc' END AS source_vocabulary_id
    FROM {{ ref('src_d_labitems') }}
)
SELECT
    dlab.itemid                 AS itemid,
    dlab.source_code            AS source_code,
    dlab.loinc_code             AS loinc_code,
    dlab.source_label           AS source_label,
    dlab.source_vocabulary_id   AS source_vocabulary_id,
    vc.domain_id                AS source_domain_id,
    vc.concept_id               AS source_concept_id,
    vc2.vocabulary_id           AS target_vocabulary_id,
    vc2.domain_id               AS target_domain_id,
    vc2.concept_id              AS target_concept_id
FROM dlab_clean dlab
LEFT JOIN {{ ref('voc_concept') }} vc
    ON  vc.concept_code = dlab.source_code
    AND vc.vocabulary_id = dlab.source_vocabulary_id
LEFT JOIN {{ ref('voc_concept_relationship') }} vcr
    ON  vc.concept_id = vcr.concept_id_1
    AND vcr.relationship_id = 'Maps to'
LEFT JOIN {{ ref('voc_concept') }} vc2
    ON  vc2.concept_id = vcr.concept_id_2
    AND vc2.standard_concept = 'S'
    AND vc2.invalid_reason IS NULL
