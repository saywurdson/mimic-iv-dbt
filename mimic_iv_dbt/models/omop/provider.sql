-- cdm_provider: de-identified providers (hosp.provider); only source id available, rest NULL.
WITH src AS (
    SELECT provider_id AS provider_source_value
    FROM {{ ref('src_provider') }}
)
SELECT
    {{ mimic_sk('provider', 'provider_source_value') }} AS provider_id,
    CAST(NULL AS VARCHAR) AS provider_name,
    CAST(NULL AS VARCHAR) AS npi,
    CAST(NULL AS VARCHAR) AS dea,
    CAST(NULL AS BIGINT)  AS specialty_concept_id,
    CAST(NULL AS BIGINT)  AS care_site_id,
    CAST(NULL AS INTEGER) AS year_of_birth,
    CAST(NULL AS BIGINT)  AS gender_concept_id,
    provider_source_value,
    CAST(NULL AS VARCHAR) AS specialty_source_value,
    CAST(NULL AS BIGINT)  AS specialty_source_concept_id,
    CAST(NULL AS VARCHAR) AS gender_source_value,
    CAST(NULL AS BIGINT)  AS gender_source_concept_id
FROM src
