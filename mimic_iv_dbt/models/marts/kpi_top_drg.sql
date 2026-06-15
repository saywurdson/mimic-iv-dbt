{{ config(materialized='table') }}

/* Top 25 DRG (Diagnosis Related Group) concepts by distinct patient count, from
   the OMOP cost table (one row per DRG code per hospitalization). Only MS-DRG
   (HCFA) codes resolve to a DRG-vocabulary concept in this ETL; APR-DRG rows land
   on concept 0 and are excluded here. person_id is recovered by joining the cost
   event back to its visit. Output columns match the kpi_top_* marts (rank,
   concept_id, concept_name, n_patients, n_records) so the dashboard renders them
   with the same helper. */

WITH c AS (
    SELECT
        v.person_id,
        c.cost_event_id,
        c.drg_concept_id
    FROM {{ ref('cost') }} c
    JOIN {{ ref('visit_occurrence') }} v ON v.visit_occurrence_id = c.cost_event_id
    WHERE c.drg_concept_id IS NOT NULL
      AND c.drg_concept_id <> 0
),

agg AS (
    SELECT
        c.drg_concept_id AS concept_id,
        cc.concept_name,
        count(DISTINCT c.person_id) AS n_patients,
        count(*) AS n_records
    FROM c
    LEFT JOIN {{ ref('concept') }} cc ON cc.concept_id = c.drg_concept_id
    GROUP BY 1, 2
)

SELECT
    row_number() OVER (ORDER BY n_patients DESC, n_records DESC) AS rank,
    concept_id,
    coalesce(concept_name, 'concept ' || concept_id::VARCHAR) AS concept_name,
    n_patients,
    n_records
FROM agg
ORDER BY n_patients DESC, n_records DESC
LIMIT 25
