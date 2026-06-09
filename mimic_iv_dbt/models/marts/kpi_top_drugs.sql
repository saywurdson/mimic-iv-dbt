{{ config(materialized='table') }}

/* Top 25 drug concepts by distinct patient count. */

{{ top_concepts('drug_exposure', 'drug_concept_id') }}
