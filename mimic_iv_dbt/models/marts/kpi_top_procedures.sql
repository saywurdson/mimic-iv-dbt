{{ config(materialized='table') }}

/* Top 25 procedure concepts by distinct patient count. */

{{ top_concepts('procedure_occurrence', 'procedure_concept_id') }}
