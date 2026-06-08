-- test-organism measurements. source = test|spec itemid; value_as_concept = organism.
SELECT
    {{ mimic_sk('meas_organism', 'src.trace_id') }}  AS measurement_id,
    src.subject_id                              AS subject_id,
    COALESCE(src.hadm_id, hadm.hadm_id)         AS hadm_id,
    CAST(src.start_datetime AS DATE)            AS date_id,
    32856                                       AS type_concept_id,
    src.start_datetime                          AS start_datetime,
    src.test_itemid                             AS test_itemid,
    src.spec_itemid                             AS spec_itemid,
    src.org_itemid                              AS org_itemid,
    CONCAT(tc.source_code, '|', sc.source_code) AS source_code,
    tc.source_vocabulary_id                     AS source_vocabulary_id,
    tc.source_concept_id                        AS source_concept_id,
    COALESCE(tc.target_domain_id, 'Measurement') AS target_domain_id,
    tc.target_concept_id                        AS target_concept_id,
    oc.source_code                              AS value_source_value,
    oc.target_concept_id                        AS value_as_concept_id,
    src.trace_id_spec                           AS trace_id_spec,
    'micro.organism'                            AS unit_id,
    src.load_table_id,
    src.trace_id
FROM {{ ref('lk_meas_organism_clean') }} src
INNER JOIN {{ ref('lk_d_micro_concept') }} tc ON src.test_itemid = tc.itemid
INNER JOIN {{ ref('lk_d_micro_concept') }} sc ON src.spec_itemid = sc.itemid
LEFT JOIN {{ ref('lk_d_micro_concept') }} oc ON src.org_itemid = oc.itemid
LEFT JOIN {{ ref('lk_micro_hadm_id') }} hadm
    ON hadm.event_trace_id = src.trace_id AND hadm.row_num = 1
