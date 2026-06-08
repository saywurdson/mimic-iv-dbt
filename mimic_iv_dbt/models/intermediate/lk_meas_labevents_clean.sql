-- labevents cleaned. measurement_id deterministic = labevents band + labevent_id.
-- operator / numeric value parsed by regex.
SELECT
    {{ mimic_sk('labevents', 'src.labevent_id') }}      AS measurement_id,
    src.subject_id                          AS subject_id,
    src.charttime                           AS start_datetime,
    src.hadm_id                             AS hadm_id,
    src.itemid                              AS itemid,
    src.value                               AS value,
    regexp_extract(src.value, '^(<=|>=|>|<|=|)')        AS value_operator,
    regexp_extract(regexp_replace(src.value, '([0-9]),([0-9])', '\1.\2'), '[-]?([0-9]*[.])?[0-9]+') AS value_number,
    CASE WHEN TRIM(src.valueuom) <> '' THEN src.valueuom ELSE NULL END AS valueuom,
    src.ref_range_lower                     AS ref_range_lower,
    src.ref_range_upper                     AS ref_range_upper,
    'labevents'                             AS unit_id,
    src.load_table_id,
    src.trace_id
FROM {{ ref('src_labevents') }} src
INNER JOIN {{ ref('src_d_labitems') }} dlab
    ON src.itemid = dlab.itemid
