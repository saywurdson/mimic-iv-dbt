{{ config(materialized='table') }}

-- OMOP RELATIONSHIP vocabulary CSV

SELECT
    relationship_id::VARCHAR AS relationship_id,
    relationship_name::VARCHAR AS relationship_name,
    is_hierarchical::VARCHAR AS is_hierarchical,
    defines_ancestry::VARCHAR AS defines_ancestry,
    reverse_relationship_id::VARCHAR AS reverse_relationship_id,
    relationship_concept_id::INTEGER AS relationship_concept_id
FROM read_csv_auto('{{ var("vocab_path") }}/RELATIONSHIP.csv', header=true, delim='\t')
