{{ config(materialized='table') }}

-- OMOP CONCEPT_CLASS vocabulary CSV

SELECT
    concept_class_id::VARCHAR AS concept_class_id,
    concept_class_name::VARCHAR AS concept_class_name,
    concept_class_concept_id::INTEGER AS concept_class_concept_id
FROM read_csv_auto('{{ var("vocab_path") }}/CONCEPT_CLASS.csv', header=true, delim='\t')
