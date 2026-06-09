{{ config(materialized='table') }}

/* Single-row headline counts for the admitted cohort. Counts are taken on the
   inpatient-admission grain defined by kpi_admission_base (see its filter to the
   inpatient visit concepts), so "patients" here are patients with at least one
   hospital admission -- not every person in the CDM, many of whom are
   outpatient/ED-only. Admission dates are de-identified (shifted into the future
   per patient), so earliest/latest describe the shifted span, not calendar
   dates. */

SELECT
    (SELECT count(*) FROM {{ ref('kpi_patient_base') }}) AS n_patients,
    (SELECT count(*) FROM {{ ref('kpi_admission_base') }}) AS n_hospital_admissions,
    (SELECT count(*) FROM {{ ref('kpi_admission_base') }} WHERE had_icu_stay) AS n_admissions_with_icu,
    (SELECT coalesce(sum(icu_stay_count), 0) FROM {{ ref('kpi_admission_base') }}) AS n_icu_stays,
    (SELECT count(*) FROM {{ ref('kpi_patient_base') }} WHERE ever_icu) AS n_icu_patients,
    (SELECT count(*) FROM {{ ref('kpi_patient_base') }} WHERE died_ever) AS n_deaths,
    (SELECT count(*) FROM {{ ref('kpi_admission_base') }} WHERE died_in_hospital) AS n_inhospital_deaths,
    (SELECT min(visit_start_date) FROM {{ ref('kpi_admission_base') }}) AS earliest_admission_shifted,
    (SELECT max(visit_start_date) FROM {{ ref('kpi_admission_base') }}) AS latest_admission_shifted
