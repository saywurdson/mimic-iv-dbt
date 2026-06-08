-- Athena relationships UNION custom 'Maps to'/'Mapped from' rows; unmapped (target=0)
-- maps concept to itself.
{{ config(materialized='table') }}

SELECT
    concept_id_1,
    concept_id_2,
    relationship_id,
    valid_start_date,
    valid_end_date,
    invalid_reason
FROM {{ ref('concept_relationship') }}

UNION ALL

-- forward: source -> target ('Maps to')
SELECT
    source_concept_id                                                   AS concept_id_1,
    CASE WHEN target_concept_id = 0 THEN source_concept_id ELSE target_concept_id END AS concept_id_2,
    relationship_id,
    relationship_valid_start_date                                       AS valid_start_date,
    relationship_end_date                                               AS valid_end_date,
    invalid_reason_cr                                                   AS invalid_reason
FROM {{ ref('int_custom_mapping') }}
WHERE target_concept_id IS NOT NULL

UNION ALL

-- reverse: target -> source ('Mapped from')
SELECT
    CASE WHEN target_concept_id = 0 THEN source_concept_id ELSE target_concept_id END AS concept_id_1,
    source_concept_id                                                   AS concept_id_2,
    reverse_relationship_id                                             AS relationship_id,
    relationship_valid_start_date                                       AS valid_start_date,
    relationship_end_date                                               AS valid_end_date,
    invalid_reason_cr                                                   AS invalid_reason
FROM {{ ref('int_custom_mapping') }}
WHERE target_concept_id IS NOT NULL
