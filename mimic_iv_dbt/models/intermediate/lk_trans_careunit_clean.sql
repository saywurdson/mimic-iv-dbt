-- distinct non-null careunits from transfers (care_site source codes)
SELECT
    careunit            AS source_code,
    load_table_id       AS load_table_id
FROM {{ ref('src_transfers') }}
WHERE careunit IS NOT NULL
GROUP BY careunit, load_table_id
