-- snapshot: hosp.d_labitems (loinc_code removed in MIMIC-IV 2.0 -> NULL)
SELECT
    itemid::BIGINT          AS itemid,
    label                   AS label,
    fluid                   AS fluid,
    category                AS category,
    CAST(NULL AS VARCHAR)   AS loinc_code,
    'd_labitems'           AS load_table_id
FROM {{ read_mimic4('d_labitems', 'hosp') }}
