-- lk_chartevents_clean: chartevents cleaned (HEAVY ~313M rows).
-- Parses embedded value+unit; filters Temperature outliers (25-44 C after F conversion).
WITH parsed AS (
    SELECT
        src.subject_id,
        src.hadm_id,
        src.stay_id,
        src.itemid,
        CAST(src.itemid AS VARCHAR)     AS source_code,
        di.label                        AS source_label,
        src.charttime                   AS start_datetime,
        TRIM(src.value)                 AS value,
        CASE WHEN regexp_extract(TRIM(src.value), '^[-]?[0-9]+[.]?[0-9]*[ ]*[a-z]+$') <> ''
             THEN TRY_CAST(regexp_extract(src.value, '[-]?[0-9]+[.]?[0-9]*') AS DOUBLE)
             ELSE src.valuenum END      AS valuenum,
        CASE WHEN regexp_extract(TRIM(src.value), '^[-]?[0-9]+[.]?[0-9]*[ ]*[a-z]+$') <> ''
             THEN regexp_extract(src.value, '[a-z]+')
             ELSE src.valueuom END      AS valueuom,
        di.label                        AS di_label,
        'chartevents'                   AS unit_id,
        src.load_table_id
    FROM {{ ref('src_chartevents') }} src
    INNER JOIN {{ ref('src_d_items') }} di
        ON src.itemid = di.itemid
)
SELECT
    subject_id, hadm_id, stay_id, itemid, source_code, source_label,
    start_datetime, value, valuenum, valueuom, unit_id, load_table_id
FROM parsed
WHERE di_label NOT LIKE '%Temperature'
   OR (di_label LIKE '%Temperature'
       AND CASE WHEN valueuom LIKE '%F%' THEN (valuenum - 32) * 5 / 9 ELSE valuenum END BETWEEN 25 AND 44)
