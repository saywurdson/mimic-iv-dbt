-- lk_admissions_clean: admissions for visit_occurrence + ER visit_detail.
-- start = earliest of edregtime/admittime; is_er_admission when edregtime present.
SELECT
    subject_id,
    hadm_id,
    CASE WHEN edregtime < admittime THEN edregtime ELSE admittime END AS start_datetime,
    dischtime                                       AS end_datetime,
    admission_type,
    admission_location,
    discharge_location,
    (edregtime IS NOT NULL)                         AS is_er_admission,
    'admissions'                                    AS unit_id,
    load_table_id
FROM {{ ref('src_admissions') }}
