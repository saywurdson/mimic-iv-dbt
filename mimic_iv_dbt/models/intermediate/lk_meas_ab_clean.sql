-- antibiotics tested on organisms.
SELECT
    src.subject_id                              AS subject_id,
    src.hadm_id                                 AS hadm_id,
    cr.start_datetime                           AS start_datetime,
    src.ab_itemid                               AS ab_itemid,
    src.dilution_comparison                     AS dilution_comparison,
    src.dilution_value                          AS dilution_value,
    src.interpretation                          AS interpretation,
    cr.trace_id_org                             AS trace_id_org,
    'micro.antibiotics'                         AS unit_id,
    src.load_table_id,
    src.trace_id                                AS trace_id
FROM {{ ref('src_microbiologyevents') }} src
INNER JOIN {{ ref('lk_micro_cross_ref') }} cr
    ON src.trace_id = cr.trace_id_ab
WHERE src.ab_itemid IS NOT NULL
