{{ config(materialized='table') }}

/* Top 20 ED chief complaints by number of ED stays. chiefcomplaint is free text
   recorded at triage (often a comma-joined combination, e.g. "Abdominal pain,
   Nausea"), so this ranks the raw strings as entered rather than mapped concepts.
   Blank/whitespace complaints are dropped. */

WITH t AS (
    SELECT trim(chiefcomplaint) AS chief_complaint
    FROM {{ ref('src_ed_triage') }}
    WHERE chiefcomplaint IS NOT NULL
      AND trim(chiefcomplaint) <> ''
)

SELECT
    row_number() OVER (ORDER BY count(*) DESC, chief_complaint) AS rank,
    chief_complaint,
    count(*) AS n_visits
FROM t
GROUP BY chief_complaint
ORDER BY n_visits DESC, chief_complaint
LIMIT 20
