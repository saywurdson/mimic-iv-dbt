-- MIMIC-IV 2.0: d_micro is generated from microbiologyevents (raw table removed).
-- One row per distinct itemid/label/category across the 4 micro itemid columns.
WITH d_micro AS (
    SELECT DISTINCT ab_itemid AS itemid, ab_name AS label, 'ANTIBIOTIC' AS category
    FROM {{ ref('src_microbiologyevents') }} WHERE ab_itemid IS NOT NULL
    UNION ALL
    SELECT DISTINCT test_itemid AS itemid, test_name AS label, 'MICROTEST' AS category
    FROM {{ ref('src_microbiologyevents') }} WHERE test_itemid IS NOT NULL
    UNION ALL
    SELECT DISTINCT org_itemid AS itemid, org_name AS label, 'ORGANISM' AS category
    FROM {{ ref('src_microbiologyevents') }} WHERE org_itemid IS NOT NULL
    UNION ALL
    SELECT DISTINCT spec_itemid AS itemid, spec_type_desc AS label, 'SPECIMEN' AS category
    FROM {{ ref('src_microbiologyevents') }} WHERE spec_itemid IS NOT NULL
)
SELECT itemid, label, category, 'microbiologyevents' AS load_table_id
FROM d_micro
