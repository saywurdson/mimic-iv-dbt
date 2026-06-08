-- snapshot: hosp.pharmacy (medication enrichment for drug names)
SELECT
    pharmacy_id::BIGINT     AS pharmacy_id,
    medication              AS medication,
    'pharmacy'             AS load_table_id
FROM {{ read_mimic4('pharmacy', 'hosp') }}
