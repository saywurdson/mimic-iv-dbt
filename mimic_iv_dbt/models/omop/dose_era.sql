-- cdm_dose_era: per-ingredient dose intervals from drug_exposure + drug_strength (OHDSI algorithm, 30-day gap).
WITH ingredient_exp AS (
    SELECT
        de.drug_exposure_id, de.person_id, de.drug_exposure_start_date, de.drug_exposure_end_date,
        de.drug_concept_id, ds.ingredient_concept_id, de.refills,
        CASE WHEN de.days_supply = 0 THEN 1 ELSE de.days_supply END AS days_supply,
        de.quantity, ds.box_size, ds.amount_value, ds.amount_unit_concept_id,
        ds.numerator_value, ds.numerator_unit_concept_id, ds.denominator_value,
        ds.denominator_unit_concept_id, c.concept_class_id
    FROM {{ ref('drug_exposure') }} de
    INNER JOIN {{ ref('voc_drug_strength') }} ds ON de.drug_concept_id = ds.drug_concept_id
    INNER JOIN {{ ref('voc_concept_ancestor') }} ca
        ON de.drug_concept_id = ca.descendant_concept_id AND ds.ingredient_concept_id = ca.ancestor_concept_id
    LEFT JOIN {{ ref('voc_concept') }} c
        ON de.drug_concept_id = c.concept_id AND c.vocabulary_id IN ('RxNorm', 'RxNorm Extension')
),
with_dose AS (
    SELECT
        drug_exposure_id, person_id, drug_exposure_start_date, drug_exposure_end_date,
        ingredient_concept_id AS drug_concept_id, refills, days_supply, quantity,
        CASE
            WHEN amount_value IS NOT NULL AND denominator_unit_concept_id IS NULL THEN
                CASE
                    WHEN quantity > 0 AND box_size IS NOT NULL AND concept_class_id IN ('Branded Drug Box','Clinical Drug Box','Marketed Product','Quant Branded Box','Quant Clinical Box')
                        THEN amount_value * quantity * box_size / days_supply
                    WHEN quantity > 0 AND concept_class_id NOT IN ('Branded Drug Box','Clinical Drug Box','Marketed Product','Quant Branded Box','Quant Clinical Box')
                        THEN amount_value * quantity / days_supply
                    WHEN quantity = 0 AND box_size IS NOT NULL THEN amount_value * box_size / days_supply
                    WHEN quantity = 0 AND box_size IS NULL THEN -1
                END
            WHEN numerator_value IS NOT NULL AND concept_class_id != 'Ingredient' AND denominator_unit_concept_id != 8505 THEN
                CASE
                    WHEN denominator_value IS NOT NULL THEN numerator_value / days_supply
                    WHEN denominator_value IS NULL AND quantity != 0 THEN numerator_value * quantity / days_supply
                    WHEN denominator_value IS NULL AND quantity = 0 THEN -1
                END
            WHEN numerator_value IS NOT NULL AND concept_class_id = 'Ingredient' AND denominator_unit_concept_id != 8505 THEN
                CASE WHEN quantity > 0 THEN quantity / days_supply WHEN quantity = 0 THEN -1 END
            WHEN numerator_value IS NOT NULL AND denominator_unit_concept_id = 8505 THEN
                CASE
                    WHEN denominator_value IS NOT NULL THEN numerator_value * 24 / denominator_value
                    WHEN denominator_value IS NULL AND quantity != 0 THEN numerator_value * 24 / quantity
                    WHEN denominator_value IS NULL AND quantity = 0 THEN -1
                END
        END AS dose_value,
        CASE
            WHEN amount_value IS NOT NULL AND denominator_unit_concept_id IS NULL THEN
                CASE WHEN quantity = 0 AND box_size IS NULL THEN -1 ELSE amount_unit_concept_id END
            WHEN numerator_value IS NOT NULL AND concept_class_id != 'Ingredient' AND denominator_unit_concept_id != 8505 THEN
                CASE WHEN denominator_value IS NULL AND quantity = 0 THEN -1 ELSE numerator_unit_concept_id END
            WHEN numerator_value IS NOT NULL AND concept_class_id = 'Ingredient' AND denominator_unit_concept_id != 8505 THEN
                CASE WHEN quantity > 0 THEN 0 WHEN quantity = 0 THEN -1 END
            WHEN numerator_value IS NOT NULL AND denominator_unit_concept_id = 8505 THEN
                CASE WHEN denominator_value IS NULL AND quantity = 0 THEN -1 ELSE numerator_unit_concept_id END
        END AS unit_concept_id
    FROM ingredient_exp
),
dose_target AS (
    SELECT
        drug_exposure_id, person_id, drug_concept_id, unit_concept_id, dose_value,
        drug_exposure_start_date, days_supply,
        COALESCE(
            drug_exposure_end_date,
            NULLIF(drug_exposure_start_date + (1 * days_supply * (COALESCE(refills, 0) + 1)) * INTERVAL 1 DAY, drug_exposure_start_date),
            drug_exposure_start_date + INTERVAL 1 DAY
        ) AS drug_exposure_end_date
    FROM with_dose
    WHERE dose_value <> -1
),
events AS (
    SELECT person_id, drug_concept_id, unit_concept_id, dose_value, drug_exposure_start_date AS event_date, -1 AS event_type,
        ROW_NUMBER() OVER (PARTITION BY person_id, drug_concept_id, unit_concept_id, CAST(dose_value AS BIGINT) ORDER BY drug_exposure_start_date) AS start_ordinal
    FROM dose_target
    UNION ALL
    SELECT person_id, drug_concept_id, unit_concept_id, dose_value, drug_exposure_end_date + INTERVAL 30 DAY, 1, NULL FROM dose_target
),
ranked AS (
    SELECT person_id, drug_concept_id, unit_concept_id, dose_value, event_date, event_type,
        MAX(start_ordinal) OVER (PARTITION BY person_id, drug_concept_id, unit_concept_id, CAST(dose_value AS BIGINT) ORDER BY event_date, event_type ROWS UNBOUNDED PRECEDING) AS start_ordinal,
        ROW_NUMBER() OVER (PARTITION BY person_id, drug_concept_id, unit_concept_id, CAST(dose_value AS BIGINT) ORDER BY event_date, event_type) AS overall_ord
    FROM events
),
ends AS (
    SELECT person_id, drug_concept_id, unit_concept_id, dose_value, event_date - INTERVAL 30 DAY AS end_date
    FROM ranked WHERE (2 * start_ordinal) - overall_ord = 0
),
final_ends AS (
    SELECT dt.person_id, dt.drug_concept_id, dt.unit_concept_id, dt.dose_value,
           dt.drug_exposure_start_date, MIN(e.end_date) AS drug_era_end_date
    FROM dose_target dt
    JOIN ends e ON dt.person_id = e.person_id AND dt.drug_concept_id = e.drug_concept_id
        AND dt.unit_concept_id = e.unit_concept_id AND dt.dose_value = e.dose_value
        AND e.end_date >= dt.drug_exposure_start_date
    GROUP BY dt.person_id, dt.drug_concept_id, dt.drug_exposure_start_date, dt.unit_concept_id, dt.dose_value
)
SELECT
    {{ mimic_sk('dose_era', 'person_id, drug_concept_id, unit_concept_id, dose_value, drug_era_end_date') }} AS dose_era_id,
    person_id,
    drug_concept_id,
    COALESCE(unit_concept_id, 0)    AS unit_concept_id,
    dose_value,
    MIN(drug_exposure_start_date)   AS dose_era_start_date,
    drug_era_end_date               AS dose_era_end_date
FROM final_ends
GROUP BY person_id, drug_concept_id, unit_concept_id, dose_value, drug_era_end_date
