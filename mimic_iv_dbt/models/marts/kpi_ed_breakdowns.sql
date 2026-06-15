{{ config(materialized='table') }}

/* Tidy (long) breakdowns of ED stays, one row per (dimension, category) with the
   ED-stay count and percent of all ED stays. Mirrors kpi_demographics in shape so
   the dashboard can render each dimension the same way. Dimensions:

     * disposition       -- where the patient went after the ED (edstays.disposition):
                            ADMITTED, HOME, TRANSFER, ...
     * arrival_transport -- how the patient arrived (edstays.arrival_transport):
                            AMBULANCE, WALK IN, ...
     * acuity            -- ESI triage acuity 1 (most urgent) .. 5 (least), from the
                            arrival triage record; ED stays with no triage row are
                            'Unknown'.

   Acuity and arrival/disposition are grouped to one row per ED stay (triage is one
   record per stay), so percentages share the same denominator (total ED stays). */

WITH ed AS (
    SELECT
        v.stay_id,
        coalesce(nullif(trim(v.disposition), ''), 'Unknown')        AS disposition,
        coalesce(nullif(trim(v.arrival_transport), ''), 'Unknown')  AS arrival_transport,
        coalesce(CAST(CAST(t.acuity AS INTEGER) AS VARCHAR), 'Unknown') AS acuity
    FROM {{ ref('lk_ed_visit') }} v
    LEFT JOIN {{ ref('src_ed_triage') }} t ON t.stay_id = v.stay_id
),

total AS (SELECT count(*) AS n FROM ed),

combined AS (
    SELECT 'disposition'       AS dimension, disposition       AS category, count(*) AS n FROM ed GROUP BY 2
    UNION ALL
    SELECT 'arrival_transport' AS dimension, arrival_transport AS category, count(*) AS n FROM ed GROUP BY 2
    UNION ALL
    SELECT 'acuity'            AS dimension, acuity             AS category, count(*) AS n FROM ed GROUP BY 2
)

SELECT
    dimension,
    category,
    n AS n_visits,
    round(100.0 * n / (SELECT n FROM total), 1) AS pct_visits
FROM combined
ORDER BY dimension, n_visits DESC
