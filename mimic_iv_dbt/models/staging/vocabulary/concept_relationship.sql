{{ config(materialized='table') }}

-- OMOP CONCEPT_RELATIONSHIP vocabulary CSV

SELECT
    concept_id_1::INTEGER AS concept_id_1,
    concept_id_2::INTEGER AS concept_id_2,
    relationship_id::VARCHAR AS relationship_id,
    -- YYYYMMDD int -> DATE
    strptime(valid_start_date::VARCHAR, '%Y%m%d')::DATE AS valid_start_date,
    strptime(valid_end_date::VARCHAR, '%Y%m%d')::DATE AS valid_end_date,
    invalid_reason::VARCHAR AS invalid_reason
FROM read_csv_auto('{{ var("vocab_path") }}/CONCEPT_RELATIONSHIP.csv', header=true, delim='\t')
