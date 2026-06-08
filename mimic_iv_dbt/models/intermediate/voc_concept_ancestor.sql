-- Passthrough of Athena concept_ancestor.
SELECT ancestor_concept_id, descendant_concept_id,
       min_levels_of_separation, max_levels_of_separation
FROM {{ ref('concept_ancestor') }}
