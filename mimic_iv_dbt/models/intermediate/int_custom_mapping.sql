-- int_custom_mapping: typed view over custom_mapping seed; one row per source concept + 'Maps to' target.
SELECT
    concept_name,
    CAST(source_concept_id AS BIGINT)       AS source_concept_id,
    source_vocabulary_id,
    source_domain_id,
    source_concept_class_id,
    NULLIF(standard_concept, '')            AS standard_concept,
    concept_code,
    TRY_CAST(valid_start_date AS DATE)      AS valid_start_date,
    TRY_CAST(valid_end_date AS DATE)        AS valid_end_date,
    NULLIF(invalid_reason, '')              AS invalid_reason,
    CAST(target_concept_id AS BIGINT)       AS target_concept_id,
    relationship_id,
    reverse_relationship_id,
    TRY_CAST(relationship_valid_start_date AS DATE) AS relationship_valid_start_date,
    TRY_CAST(relationship_end_date AS DATE)         AS relationship_end_date,
    NULLIF(invalid_reason_cr, '')           AS invalid_reason_cr
FROM {{ ref('custom_mapping') }}
