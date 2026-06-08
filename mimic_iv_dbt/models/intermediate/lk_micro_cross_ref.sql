-- group microevent trace ids: per-antibiotic, per test-organism, per specimen.
SELECT
    trace_id                                    AS trace_id_ab,
    FIRST_VALUE(src.trace_id) OVER (
        PARTITION BY src.subject_id, src.hadm_id, COALESCE(src.charttime, src.chartdate),
                     src.spec_itemid, src.test_itemid, src.org_itemid
        ORDER BY src.trace_id
    )                                           AS trace_id_org,
    FIRST_VALUE(src.trace_id) OVER (
        PARTITION BY src.subject_id, src.hadm_id, COALESCE(src.charttime, src.chartdate), src.spec_itemid
        ORDER BY src.trace_id
    )                                           AS trace_id_spec,
    subject_id                                  AS subject_id,
    hadm_id                                     AS hadm_id,
    COALESCE(src.charttime, src.chartdate)      AS start_datetime
FROM {{ ref('src_microbiologyevents') }} src
