{{ config(materialized='table') }}

-- OMOP CONCEPT_ANCESTOR vocabulary CSV

SELECT
    ancestor_concept_id::INTEGER AS ancestor_concept_id,
    descendant_concept_id::INTEGER AS descendant_concept_id,
    min_levels_of_separation::INTEGER AS min_levels_of_separation,
    max_levels_of_separation::INTEGER AS max_levels_of_separation
FROM read_csv_auto('{{ var("vocab_path") }}/CONCEPT_ANCESTOR.csv', header=true, delim='\t')
