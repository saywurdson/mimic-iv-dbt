{#
    Rank the standard concepts in an OMOP clinical table by the number of distinct
    patients (then total records). Used by the kpi_top_* marts so conditions,
    drugs, procedures, and measurements all share one ranking definition.

    Args:
      source_model       -- ref() name of the OMOP table (e.g. 'condition_occurrence')
      concept_id_column  -- the standard *_concept_id column to rank (e.g. 'condition_concept_id')
      limit              -- how many rows to keep (default 25)
#}
{% macro top_concepts(source_model, concept_id_column, limit=25) %}
WITH agg AS (
    SELECT
        t.{{ concept_id_column }} AS concept_id,
        c.concept_name,
        count(DISTINCT t.person_id) AS n_patients,
        count(*) AS n_records
    FROM {{ ref(source_model) }} t
    LEFT JOIN {{ ref('concept') }} c ON c.concept_id = t.{{ concept_id_column }}
    WHERE t.{{ concept_id_column }} IS NOT NULL
      AND t.{{ concept_id_column }} <> 0
    GROUP BY 1, 2
)
SELECT
    row_number() OVER (ORDER BY n_patients DESC, n_records DESC) AS rank,
    concept_id,
    coalesce(concept_name, 'concept ' || concept_id::VARCHAR) AS concept_name,
    n_patients,
    n_records
FROM agg
ORDER BY n_patients DESC, n_records DESC
LIMIT {{ limit }}
{% endmacro %}
