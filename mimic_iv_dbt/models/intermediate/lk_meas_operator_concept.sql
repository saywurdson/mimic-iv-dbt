-- operator name -> concept (Meas Value Operator domain).
SELECT
    concept_name    AS source_code,
    concept_id      AS target_concept_id
FROM {{ ref('voc_concept') }}
WHERE domain_id = 'Meas Value Operator'
