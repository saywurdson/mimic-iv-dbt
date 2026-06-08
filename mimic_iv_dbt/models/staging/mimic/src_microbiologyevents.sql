-- snapshot: hosp.microbiologyevents. trace_id = microevent_id (unique).
SELECT
    microevent_id::BIGINT       AS microevent_id,
    subject_id::BIGINT          AS subject_id,
    hadm_id::BIGINT             AS hadm_id,
    chartdate::TIMESTAMP        AS chartdate,
    charttime::TIMESTAMP        AS charttime,
    spec_itemid::BIGINT         AS spec_itemid,
    spec_type_desc              AS spec_type_desc,
    test_itemid::BIGINT         AS test_itemid,
    test_name                   AS test_name,
    org_itemid::BIGINT          AS org_itemid,
    org_name                    AS org_name,
    ab_itemid::BIGINT           AS ab_itemid,
    ab_name                     AS ab_name,
    dilution_comparison         AS dilution_comparison,
    dilution_value::DOUBLE      AS dilution_value,
    interpretation              AS interpretation,
    'microbiologyevents'       AS load_table_id,
    CAST(microevent_id AS VARCHAR) AS trace_id
FROM {{ read_mimic4('microbiologyevents', 'hosp', varchar_cols=['dilution_comparison','interpretation']) }}
