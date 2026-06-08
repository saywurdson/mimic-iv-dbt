-- cdm_drug_era: roll drug_exposure to RxNorm Ingredient, then 30-day-gap era collapse (OHDSI, two-pass).
WITH voc_drug AS (
    SELECT DISTINCT ca.descendant_concept_id, ca.ancestor_concept_id, c.concept_id
    FROM {{ ref('voc_concept_ancestor') }} ca
    JOIN {{ ref('voc_concept') }} c
        ON ca.ancestor_concept_id = c.concept_id
        AND c.vocabulary_id IN ('RxNorm', 'RxNorm Extension')
        AND c.concept_class_id = 'Ingredient'
),
pretarget AS (
    SELECT d.drug_exposure_id, d.person_id, v.concept_id AS ingredient_concept_id,
           d.drug_exposure_start_date, d.days_supply, d.drug_exposure_end_date
    FROM {{ ref('drug_exposure') }} d
    JOIN voc_drug v ON v.descendant_concept_id = d.drug_concept_id
    WHERE d.drug_concept_id != 0
),
-- pass 1: sub-exposure end dates (no gap pad)
sub_events AS (
    SELECT person_id, ingredient_concept_id, drug_exposure_start_date AS event_date, -1 AS event_type,
           ROW_NUMBER() OVER (PARTITION BY person_id, ingredient_concept_id ORDER BY drug_exposure_start_date) AS start_ordinal
    FROM pretarget
    UNION ALL
    SELECT person_id, ingredient_concept_id, drug_exposure_end_date, 1, NULL FROM pretarget
),
sub_ranked AS (
    SELECT person_id, ingredient_concept_id, event_date, event_type,
        MAX(start_ordinal) OVER (PARTITION BY person_id, ingredient_concept_id ORDER BY event_date, event_type ROWS UNBOUNDED PRECEDING) AS start_ordinal,
        ROW_NUMBER() OVER (PARTITION BY person_id, ingredient_concept_id ORDER BY event_date, event_type) AS overall_ord
    FROM sub_events
),
sub_ends AS (
    SELECT person_id, ingredient_concept_id, event_date AS end_date
    FROM sub_ranked WHERE (2 * start_ordinal) - overall_ord = 0
),
temp_ends AS (
    SELECT dt.person_id, dt.ingredient_concept_id AS drug_concept_id, dt.drug_exposure_start_date,
           MIN(e.end_date) AS drug_sub_exposure_end_date
    FROM pretarget dt
    JOIN sub_ends e ON dt.person_id = e.person_id AND dt.ingredient_concept_id = e.ingredient_concept_id
        AND e.end_date >= dt.drug_exposure_start_date
    GROUP BY dt.person_id, dt.ingredient_concept_id, dt.drug_exposure_start_date
),
sub AS (
    SELECT person_id, drug_concept_id,
           MIN(drug_exposure_start_date) AS drug_sub_exposure_start_date,
           drug_sub_exposure_end_date,
           COUNT(*) AS drug_exposure_count
    FROM temp_ends
    GROUP BY person_id, drug_concept_id, drug_sub_exposure_end_date
),
finaltarget AS (
    SELECT person_id, drug_concept_id AS ingredient_concept_id,
           drug_sub_exposure_start_date, drug_sub_exposure_end_date, drug_exposure_count,
           date_diff('day', drug_sub_exposure_start_date, drug_sub_exposure_end_date) AS days_exposed
    FROM sub
),
-- pass 2: era end dates (30-day pad)
era_events AS (
    SELECT person_id, ingredient_concept_id, drug_sub_exposure_start_date AS event_date, -1 AS event_type,
           ROW_NUMBER() OVER (PARTITION BY person_id, ingredient_concept_id ORDER BY drug_sub_exposure_start_date) AS start_ordinal
    FROM finaltarget
    UNION ALL
    SELECT person_id, ingredient_concept_id, drug_sub_exposure_end_date + INTERVAL 30 DAY, 1, NULL FROM finaltarget
),
era_ranked AS (
    SELECT person_id, ingredient_concept_id, event_date, event_type,
        MAX(start_ordinal) OVER (PARTITION BY person_id, ingredient_concept_id ORDER BY event_date, event_type ROWS UNBOUNDED PRECEDING) AS start_ordinal,
        ROW_NUMBER() OVER (PARTITION BY person_id, ingredient_concept_id ORDER BY event_date, event_type) AS overall_ord
    FROM era_events
),
era_ends AS (
    SELECT person_id, ingredient_concept_id, event_date - INTERVAL 30 DAY AS end_date
    FROM era_ranked WHERE (2 * start_ordinal) - overall_ord = 0
),
drugera_ends AS (
    SELECT ft.person_id, ft.ingredient_concept_id, ft.drug_sub_exposure_start_date,
           MIN(e.end_date) AS drug_era_end_date, ft.drug_exposure_count, ft.days_exposed
    FROM finaltarget ft
    JOIN era_ends e ON ft.person_id = e.person_id AND ft.ingredient_concept_id = e.ingredient_concept_id
        AND e.end_date >= ft.drug_sub_exposure_start_date
    GROUP BY ft.person_id, ft.days_exposed, ft.drug_exposure_count,
             ft.ingredient_concept_id, ft.drug_sub_exposure_start_date
)
SELECT
    {{ mimic_sk('drug_era', 'person_id, ingredient_concept_id, drug_era_end_date') }} AS drug_era_id,
    person_id,
    ingredient_concept_id           AS drug_concept_id,
    MIN(drug_sub_exposure_start_date) AS drug_era_start_date,
    drug_era_end_date               AS drug_era_end_date,
    SUM(drug_exposure_count)        AS drug_exposure_count,
    date_diff('day', MIN(drug_sub_exposure_start_date), drug_era_end_date) - SUM(days_exposed) AS gap_days
FROM drugera_ends
GROUP BY person_id, drug_era_end_date, ingredient_concept_id
