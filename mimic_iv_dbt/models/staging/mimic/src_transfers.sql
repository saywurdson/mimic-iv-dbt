-- snapshot: hosp.transfers
SELECT
    transfer_id::BIGINT     AS transfer_id,
    hadm_id::BIGINT         AS hadm_id,
    subject_id::BIGINT      AS subject_id,
    careunit                AS careunit,
    intime::TIMESTAMP       AS intime,
    outtime::TIMESTAMP      AS outtime,
    eventtype               AS eventtype,
    'transfers'            AS load_table_id
FROM {{ read_mimic4('transfers', 'hosp') }}
