-- cdm_care_site: one row per transfers careunit, place_of_service via mimiciv_cs_place_of_service.
SELECT
    {{ mimic_sk('care_site', 'src.source_code') }}  AS care_site_id,
    src.source_code                     AS care_site_name,
    CASE WHEN da.domain_id = 'Place of Service' THEN (vc2.concept_id) ELSE 0 END AS place_of_service_concept_id,
    1                                   AS location_id,        -- hard-coded BIDMC
    src.source_code                     AS care_site_source_value,
    src.source_code                     AS place_of_service_source_value
FROM {{ ref('lk_trans_careunit_clean') }} src
LEFT JOIN {{ ref('voc_concept') }} vc
    ON  vc.concept_code = src.source_code
    AND vc.vocabulary_id = 'mimiciv_cs_place_of_service'
LEFT JOIN {{ ref('voc_concept_relationship') }} vcr
    ON  vc.concept_id = vcr.concept_id_1
    AND vcr.relationship_id = 'Maps to'
LEFT JOIN {{ ref('voc_concept') }} vc2
    ON  vc2.concept_id = vcr.concept_id_2
    AND vc2.standard_concept = 'S'
    AND vc2.invalid_reason IS NULL
LEFT JOIN {{ ref('voc_concept') }} da ON da.concept_id = (vc2.concept_id)
