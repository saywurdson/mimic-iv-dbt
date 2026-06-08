-- test-organism pairs (one row per test-organism, grouped by trace_id_org).
SELECT DISTINCT
    src.subject_id                              AS subject_id,
    src.hadm_id                                 AS hadm_id,
    cr.start_datetime                           AS start_datetime,
    src.spec_itemid                             AS spec_itemid,
    src.test_itemid                             AS test_itemid,
    src.org_itemid                              AS org_itemid,
    cr.trace_id_spec                            AS trace_id_spec,
    'micro.organism'                            AS unit_id,
    src.load_table_id,
    cr.trace_id_org                             AS trace_id
FROM {{ ref('src_microbiologyevents') }} src
INNER JOIN {{ ref('lk_micro_cross_ref') }} cr
    ON src.trace_id = cr.trace_id_org
