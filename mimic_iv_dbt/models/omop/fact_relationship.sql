-- cdm_fact_relationship: symmetric specimen<->organism and organism<->antibiotic measurement pairs.
-- Guards restrict to facts actually emitted (event-less patients dropped downstream).
WITH spec_org AS (
    SELECT spec.specimen_id, org.measurement_id
    FROM {{ ref('lk_specimen_mapped') }} spec
    INNER JOIN {{ ref('lk_meas_organism_mapped') }} org ON org.trace_id_spec = spec.trace_id
    WHERE spec.specimen_id IN (SELECT specimen_id FROM {{ ref('specimen') }})
      AND org.measurement_id IN (SELECT measurement_id FROM {{ ref('measurement') }})
),
org_ab AS (
    SELECT org.measurement_id AS org_measurement_id, ab.measurement_id AS ab_measurement_id
    FROM {{ ref('lk_meas_organism_mapped') }} org
    INNER JOIN {{ ref('lk_meas_ab_mapped') }} ab ON ab.trace_id_org = org.trace_id
    WHERE org.measurement_id IN (SELECT measurement_id FROM {{ ref('measurement') }})
      AND ab.measurement_id IN (SELECT measurement_id FROM {{ ref('measurement') }})
)
SELECT 36 AS domain_concept_id_1, specimen_id AS fact_id_1, 21 AS domain_concept_id_2,
       measurement_id AS fact_id_2, 32669 AS relationship_concept_id, 'fact.spec.test' AS unit_id
FROM spec_org
UNION ALL
SELECT 21, measurement_id, 36, specimen_id, 32668, 'fact.test.spec' FROM spec_org
UNION ALL
SELECT 21, org_measurement_id, 21, ab_measurement_id, 581436, 'fact.test.ab' FROM org_ab
UNION ALL
SELECT 21, ab_measurement_id, 21, org_measurement_id, 581437, 'fact.ab.test' FROM org_ab
