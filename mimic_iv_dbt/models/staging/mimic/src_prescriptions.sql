-- snapshot: hosp.prescriptions (ndc forced VARCHAR)
SELECT
    hadm_id::BIGINT         AS hadm_id,
    subject_id::BIGINT      AS subject_id,
    pharmacy_id::BIGINT     AS pharmacy_id,
    starttime::TIMESTAMP    AS starttime,
    stoptime::TIMESTAMP     AS stoptime,
    drug_type               AS drug_type,
    drug                    AS drug,
    gsn                     AS gsn,
    ndc                     AS ndc,
    prod_strength           AS prod_strength,
    form_rx                 AS form_rx,
    dose_val_rx             AS dose_val_rx,
    dose_unit_rx            AS dose_unit_rx,
    form_val_disp           AS form_val_disp,
    form_unit_disp          AS form_unit_disp,
    doses_per_24_hrs        AS doses_per_24_hrs,
    route                   AS route,
    'prescriptions'        AS load_table_id
FROM {{ read_mimic4('prescriptions', 'hosp', varchar_cols=['ndc','gsn','dose_val_rx','form_val_disp']) }}
