{{ config(materialized='table') }}

-- Deliverable CONCEPT: Athena vocabulary UNION the custom MIMIC-IV local concepts
-- (int_custom_mapping, ids >= 2e9) so every source/local concept resolves.
SELECT
    concept_id::BIGINT AS concept_id,
    concept_name::VARCHAR AS concept_name,
    domain_id::VARCHAR AS domain_id,
    vocabulary_id::VARCHAR AS vocabulary_id,
    concept_class_id::VARCHAR AS concept_class_id,
    standard_concept::VARCHAR AS standard_concept,
    concept_code::VARCHAR AS concept_code,
    strptime(valid_start_date::VARCHAR, '%Y%m%d')::DATE AS valid_start_date,
    strptime(valid_end_date::VARCHAR, '%Y%m%d')::DATE AS valid_end_date,
    invalid_reason::VARCHAR AS invalid_reason
FROM read_csv_auto('{{ var("vocab_path") }}/CONCEPT.csv', header=true, delim='\t')

UNION ALL

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
WHERE source_concept_id >= 2000000000
