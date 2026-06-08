-- specimen mapped (mimiciv_micro_specimen 'Maps to').
SELECT
    {{ mimic_sk('specimen', 'src.trace_id') }}  AS specimen_id,
    src.subject_id                              AS subject_id,
    COALESCE(src.hadm_id, hadm.hadm_id)         AS hadm_id,
    CAST(src.start_datetime AS DATE)            AS date_id,
    32856                                       AS type_concept_id,
    src.start_datetime                          AS start_datetime,
    src.spec_itemid                             AS spec_itemid,
    mc.source_code                              AS source_code,
    mc.source_vocabulary_id                     AS source_vocabulary_id,
    mc.source_concept_id                        AS source_concept_id,
    COALESCE(mc.target_domain_id, 'Specimen')   AS target_domain_id,
    mc.target_concept_id                        AS target_concept_id,
    'micro.specimen'                            AS unit_id,
    src.load_table_id,
    src.trace_id
FROM {{ ref('lk_specimen_clean') }} src
INNER JOIN {{ ref('lk_d_micro_concept') }} mc
    ON src.spec_itemid = mc.itemid
LEFT JOIN {{ ref('lk_micro_hadm_id') }} hadm
    ON hadm.event_trace_id = src.trace_id AND hadm.row_num = 1
