-- snapshot: hosp.provider (the de-identified provider id list)
SELECT
    provider_id             AS provider_id,
    'provider'              AS load_table_id
FROM {{ read_mimic4('provider', 'hosp', varchar_cols=['provider_id']) }}
