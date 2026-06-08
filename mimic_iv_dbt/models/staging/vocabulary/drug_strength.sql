{{ config(materialized='table') }}

-- OMOP DRUG_STRENGTH vocabulary CSV

SELECT
    drug_concept_id::INTEGER AS drug_concept_id,
    ingredient_concept_id::INTEGER AS ingredient_concept_id,
    amount_value::FLOAT AS amount_value,
    amount_unit_concept_id::INTEGER AS amount_unit_concept_id,
    numerator_value::FLOAT AS numerator_value,
    numerator_unit_concept_id::INTEGER AS numerator_unit_concept_id,
    denominator_value::FLOAT AS denominator_value,
    denominator_unit_concept_id::INTEGER AS denominator_unit_concept_id,
    box_size::INTEGER AS box_size,
    -- YYYYMMDD int -> DATE
    strptime(valid_start_date::VARCHAR, '%Y%m%d')::DATE AS valid_start_date,
    strptime(valid_end_date::VARCHAR, '%Y%m%d')::DATE AS valid_end_date,
    invalid_reason::VARCHAR AS invalid_reason
FROM read_csv_auto('{{ var("vocab_path") }}/DRUG_STRENGTH.csv', header=true, delim='\t')
