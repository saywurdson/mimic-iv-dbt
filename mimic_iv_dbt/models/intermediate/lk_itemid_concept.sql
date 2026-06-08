-- lk_itemid_concept: d_items itemids (procedureevents/datetimeevents) -> standard.
SELECT
    d_items.itemid                      AS itemid,
    CAST(d_items.itemid AS VARCHAR)     AS source_code,
    d_items.label                       AS source_label,
    vc.vocabulary_id                    AS source_vocabulary_id,
    vc.domain_id                        AS source_domain_id,
    vc.concept_id                       AS source_concept_id,
    vc2.domain_id                       AS target_domain_id,
    vc2.concept_id                      AS target_concept_id
FROM {{ ref('src_d_items') }} d_items
LEFT JOIN {{ ref('voc_concept') }} vc
    ON  vc.concept_code = CAST(d_items.itemid AS VARCHAR)
    AND vc.vocabulary_id IN ('mimiciv_proc_itemid', 'mimiciv_proc_datetimeevents')
LEFT JOIN {{ ref('voc_concept_relationship') }} vcr
    ON vc.concept_id = vcr.concept_id_1 AND vcr.relationship_id = 'Maps to'
LEFT JOIN {{ ref('voc_concept') }} vc2
    ON vc2.concept_id = vcr.concept_id_2 AND vc2.standard_concept = 'S' AND vc2.invalid_reason IS NULL
WHERE d_items.linksto IN ('procedureevents', 'datetimeevents')
