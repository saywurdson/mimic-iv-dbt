-- prescriptions cleaned; container-label drugs substituted with pharmacy medication.
SELECT
    src.subject_id              AS subject_id,
    src.hadm_id                 AS hadm_id,
    src.dose_val_rx             AS dose_val_rx,
    src.starttime               AS start_datetime,
    COALESCE(src.stoptime, src.starttime) AS end_datetime,
    src.route                   AS route_source_code,
    'mimiciv_drug_route'        AS route_source_vocabulary,
    src.form_unit_disp          AS dose_unit_source_code,
    CAST(src.ndc AS VARCHAR)    AS ndc_source_code,
    'NDC'                       AS ndc_source_vocabulary,
    src.form_val_disp           AS form_val_disp,
    TRY_CAST(regexp_extract(src.form_val_disp, '[-]?[0-9]+[.]?[0-9]*') AS DOUBLE) AS quantity,
    TRIM(COALESCE(
        CASE WHEN src.drug IN ('Bag','Vial','Syringe','Syringe.','Syringe (Neonatal)',
                               'Syringe (Chemo)','Soln','Soln.','Sodium Chloride 0.9%  Flush')
             THEN pharm.medication ELSE src.drug END, '')
        || ' ' || COALESCE(src.prod_strength, '')) AS gcpt_source_code,
    'mimiciv_drug_ndc'                          AS gcpt_source_vocabulary,
    src.pharmacy_id                             AS pharmacy_id,
    'prescriptions'                             AS unit_id,
    src.load_table_id
FROM {{ ref('src_prescriptions') }} src
LEFT JOIN {{ ref('src_pharmacy') }} pharm ON src.pharmacy_id = pharm.pharmacy_id
WHERE src.starttime IS NOT NULL AND src.drug IS NOT NULL
