{#
    Emit the custom schema name as-is (no <target.schema>_ prefix), so models land
    in `omop` / `staging` / `intermediate` / `vocab` / `reference` rather than
    `main_omop` etc. Mirrors the MIMIC-III project.
#}

{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- set default_schema = target.schema -%}
    {%- if custom_schema_name is not none -%}
        {{ custom_schema_name | trim }}
    {%- else -%}
        {{ default_schema }}
    {%- endif -%}
{%- endmacro %}
