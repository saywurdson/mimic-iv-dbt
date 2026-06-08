{{ config(materialized='table') }}

-- OMOP DOMAIN vocabulary CSV

SELECT
    domain_id::VARCHAR AS domain_id,
    domain_name::VARCHAR AS domain_name,
    domain_concept_id::INTEGER AS domain_concept_id
FROM read_csv_auto('{{ var("vocab_path") }}/DOMAIN.csv', header=true, delim='\t')
