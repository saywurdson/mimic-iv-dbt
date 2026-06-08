-- Passthrough of Athena vocabulary.
SELECT * FROM {{ ref('vocabulary') }}
