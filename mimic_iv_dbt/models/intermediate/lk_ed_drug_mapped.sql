-- lk_ed_drug_mapped: ED meds (ed.medrecon + ed.pyxis) -> RxNorm standard, domain Drug.
-- medrecon: NDC 'Maps to' standard (mirrors lk_drug_mapped); falls back to the gsn_to_rxnorm
-- seed on medrecon.gsn when the NDC has no standard map. pyxis has no NDC, so it maps via the
-- gsn_to_rxnorm seed on pyxis.gsn only. drug_type_concept_id=32838 (same as lk_drug_mapped),
-- start=end=charttime, route 0 (no route recorded in ED med tables).
WITH ndc_concept AS (
    SELECT DISTINCT
        CAST(src.ndc AS VARCHAR) AS source_code,
        vc.concept_id AS source_concept_id,
        vc2.domain_id AS target_domain_id,
        vc2.concept_id AS target_concept_id
    FROM {{ ref('src_ed_medrecon') }} src
    LEFT JOIN {{ ref('voc_concept') }} vc
        ON vc.concept_code = CAST(src.ndc AS VARCHAR) AND vc.vocabulary_id = 'NDC'
    LEFT JOIN {{ ref('voc_concept_relationship') }} vcr
        ON vc.concept_id = vcr.concept_id_1 AND vcr.relationship_id = 'Maps to'
    LEFT JOIN {{ ref('voc_concept') }} vc2
        ON vc2.concept_id = vcr.concept_id_2 AND vc2.standard_concept = 'S' AND vc2.invalid_reason IS NULL
),
medrecon_mapped AS (
    SELECT
        src.subject_id                                  AS subject_id,
        src.stay_id                                     AS stay_id,
        COALESCE(vc_ndc.target_concept_id, gsn.drug_concept_id, 0)                AS target_concept_id,
        COALESCE(vc_ndc.target_domain_id, 'Drug')       AS target_domain_id,
        src.charttime                                   AS start_datetime,
        src.charttime                                   AS end_datetime,
        32838                                           AS type_concept_id,
        0                                               AS route_concept_id,
        COALESCE(vc_ndc.source_code, src.gsn)           AS source_code,
        COALESCE(vc_ndc.source_concept_id, gsn.drug_source_concept_id, 0)         AS source_concept_id,
        src.load_table_id                               AS load_table_id
    FROM {{ ref('src_ed_medrecon') }} src
    LEFT JOIN ndc_concept vc_ndc
        ON CAST(src.ndc AS VARCHAR) = vc_ndc.source_code AND vc_ndc.target_concept_id IS NOT NULL
    LEFT JOIN {{ ref('gsn_to_rxnorm') }} gsn
        ON src.gsn = gsn.gsn AND vc_ndc.target_concept_id IS NULL
),
pyxis_mapped AS (
    SELECT
        src.subject_id                                  AS subject_id,
        src.stay_id                                     AS stay_id,
        COALESCE(gsn.drug_concept_id, 0)                AS target_concept_id,
        'Drug'                                          AS target_domain_id,
        src.charttime                                   AS start_datetime,
        src.charttime                                   AS end_datetime,
        32838                                           AS type_concept_id,
        0                                               AS route_concept_id,
        src.gsn                                         AS source_code,
        COALESCE(gsn.drug_source_concept_id, 0)         AS source_concept_id,
        src.load_table_id                               AS load_table_id
    FROM {{ ref('src_ed_pyxis') }} src
    LEFT JOIN {{ ref('gsn_to_rxnorm') }} gsn
        ON src.gsn = gsn.gsn
)
SELECT * FROM medrecon_mapped
UNION ALL
SELECT * FROM pyxis_mapped
