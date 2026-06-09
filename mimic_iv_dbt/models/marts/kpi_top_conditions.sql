{{ config(materialized='table') }}

/* Top 25 condition (diagnosis) concepts by distinct patient count. */

{{ top_concepts('condition_occurrence', 'condition_concept_id') }}
