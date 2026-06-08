{{ config(materialized='table') }}

-- OMOP CONCEPT_SYNONYM vocabulary CSV

SELECT
    concept_id::INTEGER AS concept_id,
    concept_synonym_name::VARCHAR AS concept_synonym_name,
    language_concept_id::INTEGER AS language_concept_id
FROM read_csv_auto('{{ var("vocab_path") }}/CONCEPT_SYNONYM.csv', header=true, delim='\t')
