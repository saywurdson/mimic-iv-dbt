-- specimens (one row per specimen, grouped by trace_id_spec).
SELECT DISTINCT
    src.subject_id                              AS subject_id,
    src.hadm_id                                 AS hadm_id,
    src.start_datetime                          AS start_datetime,
    src.spec_itemid                             AS spec_itemid,
    'micro.specimen'                            AS unit_id,
    src.load_table_id,
    cr.trace_id_spec                            AS trace_id
FROM {{ ref('lk_meas_organism_clean') }} src
INNER JOIN {{ ref('lk_micro_cross_ref') }} cr
    ON src.trace_id = cr.trace_id_spec
