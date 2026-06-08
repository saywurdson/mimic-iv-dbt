-- Working concept table: standard Athena concepts (< 2e9) UNION custom 2-billion concepts.
{{ config(materialized='table') }}

SELECT
    concept_id,
    concept_name,
    domain_id,
    vocabulary_id,
    concept_class_id,
    standard_concept,
    concept_code,
    valid_start_date,
    valid_end_date,
    invalid_reason
FROM {{ ref('concept') }}
WHERE concept_id < 2000000000

UNION ALL

-- custom source concepts; standard_concept = 'S' when unmapped (target=0), else CSV value.
SELECT DISTINCT
    source_concept_id                       AS concept_id,
    concept_name,
    source_domain_id                        AS domain_id,
    source_vocabulary_id                    AS vocabulary_id,
    source_concept_class_id                 AS concept_class_id,
    CASE WHEN target_concept_id = 0 THEN 'S' ELSE standard_concept END AS standard_concept,
    concept_code,
    valid_start_date,
    valid_end_date,
    invalid_reason
FROM {{ ref('int_custom_mapping') }}
