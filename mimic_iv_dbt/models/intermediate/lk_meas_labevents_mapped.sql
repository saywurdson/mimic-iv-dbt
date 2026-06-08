-- labevents mapped: itemid concept + unit + operator + backfilled hadm_id.
SELECT
    src.measurement_id                      AS measurement_id,
    src.subject_id                          AS subject_id,
    COALESCE(src.hadm_id, hadm.hadm_id)     AS hadm_id,
    CAST(src.start_datetime AS DATE)        AS date_id,
    src.start_datetime                      AS start_datetime,
    src.itemid                              AS itemid,
    CAST(src.itemid AS VARCHAR)             AS source_code,
    labc.source_vocabulary_id               AS source_vocabulary_id,
    labc.source_concept_id                  AS source_concept_id,
    COALESCE(labc.target_domain_id, 'Measurement') AS target_domain_id,
    labc.target_concept_id                  AS target_concept_id,
    src.valueuom                            AS unit_source_value,
    CASE WHEN src.valueuom IS NOT NULL THEN COALESCE(uc.target_concept_id, 0) END AS unit_concept_id,
    src.value_operator                      AS operator_source_value,
    opc.target_concept_id                   AS operator_concept_id,
    src.value                               AS value_source_value,
    TRY_CAST(src.value_number AS DOUBLE)    AS value_as_number,
    CAST(NULL AS BIGINT)                    AS value_as_concept_id,
    src.ref_range_lower                     AS range_low,
    src.ref_range_upper                     AS range_high,
    'meas.labevents'                        AS unit_id,
    src.load_table_id,
    src.trace_id
FROM {{ ref('lk_meas_labevents_clean') }} src
INNER JOIN {{ ref('lk_meas_d_labitems_concept') }} labc
    ON labc.itemid = src.itemid
LEFT JOIN {{ ref('lk_meas_operator_concept') }} opc
    ON opc.source_code = src.value_operator
LEFT JOIN {{ ref('lk_meas_unit_concept') }} uc
    ON uc.source_code = src.valueuom
LEFT JOIN {{ ref('lk_meas_labevents_hadm_id') }} hadm
    ON hadm.event_trace_id = src.trace_id AND hadm.row_num = 1
