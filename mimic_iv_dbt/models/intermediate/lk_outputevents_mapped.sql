-- outputevents mapped (mimiciv_outputevents 'Maps to'); itemid 227488 negated.
WITH clean AS (
    SELECT
        src.subject_id, src.hadm_id, src.stay_id, src.itemid,
        CAST(src.itemid AS VARCHAR) AS source_code,
        di.label AS source_label,
        src.charttime AS start_datetime,
        src.value AS valuenum,
        src.valueuom AS valueuom,
        'outputevents' AS unit_id, src.load_table_id
    FROM {{ ref('src_outputevents') }} src
    INNER JOIN {{ ref('src_d_items') }} di ON src.itemid = di.itemid
)
SELECT
    {{ mimic_sk('outputevents', 'src.subject_id, src.stay_id, src.start_datetime, src.itemid') }} AS measurement_id,
    src.subject_id                                  AS subject_id,
    src.hadm_id                                     AS hadm_id,
    src.stay_id                                     AS stay_id,
    src.start_datetime                              AS start_datetime,
    32817                                           AS type_concept_id,
    src.itemid                                      AS itemid,
    src.source_code                                 AS source_code,
    src.source_label                                AS source_label,
    c.vocabulary_id                                 AS vocabulary_id,
    c.domain_id                                     AS source_domain_id,
    c.concept_id                                    AS source_concept_id,
    c2.domain_id                                    AS target_domain_id,
    c2.concept_id                                   AS target_concept_id,
    CAST(src.valuenum AS VARCHAR)                   AS value_source_value,
    0                                               AS value_as_concept_id,
    CASE WHEN src.itemid = 227488 THEN -src.valuenum ELSE src.valuenum END AS value_as_number,
    src.valueuom                                    AS unit_source_value,
    CASE WHEN src.valueuom IS NOT NULL THEN COALESCE(uc.target_concept_id, 0) END AS unit_concept_id,
    'meas.outputevents'                             AS unit_id,
    src.load_table_id
FROM clean src
LEFT JOIN {{ ref('voc_concept') }} c
    ON src.source_code = c.concept_code AND c.vocabulary_id = 'mimiciv_outputevents'
LEFT JOIN {{ ref('voc_concept_relationship') }} cr
    ON c.concept_id = cr.concept_id_1 AND cr.relationship_id = 'Maps to'
LEFT JOIN {{ ref('voc_concept') }} c2
    ON cr.concept_id_2 = c2.concept_id AND c2.standard_concept = 'S' AND c2.invalid_reason IS NULL
LEFT JOIN {{ ref('lk_meas_unit_concept') }} uc
    ON src.valueuom = uc.source_code
