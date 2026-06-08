-- lk_drug_mapped: NDC 'Maps to' (preferred) else gcpt; route via mimiciv_drug_route.
-- Fans out Drug/Device.
WITH ndc_concept AS (
    SELECT DISTINCT
        src.ndc_source_code AS source_code,
        vc.concept_id AS source_concept_id,
        vc2.domain_id AS target_domain_id,
        vc2.concept_id AS target_concept_id
    FROM {{ ref('lk_prescriptions_clean') }} src
    LEFT JOIN {{ ref('voc_concept') }} vc
        ON vc.concept_code = src.ndc_source_code AND vc.vocabulary_id = src.ndc_source_vocabulary
    LEFT JOIN {{ ref('voc_concept_relationship') }} vcr
        ON vc.concept_id = vcr.concept_id_1 AND vcr.relationship_id = 'Maps to'
    LEFT JOIN {{ ref('voc_concept') }} vc2
        ON vc2.concept_id = vcr.concept_id_2 AND vc2.standard_concept = 'S' AND vc2.invalid_reason IS NULL
),
gcpt_concept AS (
    SELECT DISTINCT
        src.gcpt_source_code AS source_code,
        vc.concept_id AS source_concept_id,
        vc2.domain_id AS target_domain_id,
        vc2.concept_id AS target_concept_id
    FROM {{ ref('lk_prescriptions_clean') }} src
    LEFT JOIN {{ ref('voc_concept') }} vc
        ON vc.concept_code = src.gcpt_source_code AND vc.vocabulary_id = src.gcpt_source_vocabulary
    LEFT JOIN {{ ref('voc_concept_relationship') }} vcr
        ON vc.concept_id = vcr.concept_id_1 AND vcr.relationship_id = 'Maps to'
    LEFT JOIN {{ ref('voc_concept') }} vc2
        ON vc2.concept_id = vcr.concept_id_2 AND vc2.standard_concept = 'S' AND vc2.invalid_reason IS NULL
),
route_concept AS (
    SELECT DISTINCT
        src.route_source_code AS source_code,
        vc2.concept_id AS target_concept_id
    FROM {{ ref('lk_prescriptions_clean') }} src
    LEFT JOIN {{ ref('voc_concept') }} vc
        ON vc.concept_code = src.route_source_code AND vc.vocabulary_id = src.route_source_vocabulary
    LEFT JOIN {{ ref('voc_concept_relationship') }} vcr
        ON vc.concept_id = vcr.concept_id_1 AND vcr.relationship_id = 'Maps to'
    LEFT JOIN {{ ref('voc_concept') }} vc2
        ON vc2.concept_id = vcr.concept_id_2 AND vc2.standard_concept = 'S' AND vc2.invalid_reason IS NULL
)
SELECT
    src.hadm_id                                     AS hadm_id,
    src.subject_id                                  AS subject_id,
    COALESCE(vc_ndc.target_concept_id, vc_gcpt.target_concept_id, 0)    AS target_concept_id,
    COALESCE(vc_ndc.target_domain_id, vc_gcpt.target_domain_id, 'Drug') AS target_domain_id,
    src.start_datetime                              AS start_datetime,
    CASE WHEN src.end_datetime < src.start_datetime THEN src.start_datetime ELSE src.end_datetime END AS end_datetime,
    32838                                           AS type_concept_id,
    src.quantity                                    AS quantity,
    COALESCE(vc_route.target_concept_id, 0)         AS route_concept_id,
    COALESCE(vc_ndc.source_code, vc_gcpt.source_code, src.gcpt_source_code) AS source_code,
    COALESCE(vc_ndc.source_concept_id, vc_gcpt.source_concept_id, 0)    AS source_concept_id,
    src.route_source_code                           AS route_source_code,
    src.dose_unit_source_code                       AS dose_unit_source_code,
    src.form_val_disp                               AS quantity_source_value,
    src.pharmacy_id                                 AS pharmacy_id,
    'drug.prescriptions'                            AS unit_id,
    src.load_table_id
FROM {{ ref('lk_prescriptions_clean') }} src
LEFT JOIN ndc_concept vc_ndc
    ON src.ndc_source_code = vc_ndc.source_code AND vc_ndc.target_concept_id IS NOT NULL
LEFT JOIN gcpt_concept vc_gcpt
    ON src.gcpt_source_code = vc_gcpt.source_code AND vc_gcpt.target_concept_id IS NOT NULL
LEFT JOIN route_concept vc_route
    ON src.route_source_code = vc_route.source_code AND vc_route.target_concept_id IS NOT NULL
