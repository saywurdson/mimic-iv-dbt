-- cdm_location: single constant row (Beth Israel Hospital, MA).
SELECT
    1                           AS location_id,
    CAST(NULL AS VARCHAR)       AS address_1,
    CAST(NULL AS VARCHAR)       AS address_2,
    CAST(NULL AS VARCHAR)       AS city,
    'MA'                        AS state,
    CAST(NULL AS VARCHAR)       AS zip,
    CAST(NULL AS VARCHAR)       AS county,
    'Beth Israel Hospital'      AS location_source_value
