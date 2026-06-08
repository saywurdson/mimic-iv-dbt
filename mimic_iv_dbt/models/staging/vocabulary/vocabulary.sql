{{ config(materialized='table') }}

-- OMOP VOCABULARY vocabulary CSV

SELECT
    vocabulary_id::VARCHAR AS vocabulary_id,
    vocabulary_name::VARCHAR AS vocabulary_name,
    vocabulary_reference::VARCHAR AS vocabulary_reference,
    vocabulary_version::VARCHAR AS vocabulary_version,
    vocabulary_concept_id::INTEGER AS vocabulary_concept_id
FROM read_csv_auto('{{ var("vocab_path") }}/VOCABULARY.csv', header=true, delim='\t')
