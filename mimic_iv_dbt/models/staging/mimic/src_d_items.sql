-- snapshot: icu.d_items
SELECT
    itemid::BIGINT          AS itemid,
    label                   AS label,
    linksto                 AS linksto,
    'd_items'              AS load_table_id
FROM {{ read_mimic4('d_items', 'icu') }}
