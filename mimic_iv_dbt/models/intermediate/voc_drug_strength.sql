-- Passthrough of Athena drug_strength.
SELECT * FROM {{ ref('drug_strength') }}
