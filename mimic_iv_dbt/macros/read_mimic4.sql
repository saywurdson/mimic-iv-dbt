{#
    Read a raw MIMIC-IV gzipped CSV from <mimic4_path>/<module>/<table>.csv.gz.
    Columns keep their original (lower) header names; DuckDB identifiers are
    case-insensitive so downstream models reference them in lower case.

    `varchar_cols` forces specific columns to VARCHAR so code/value columns with
    leading zeros or mixed content (icd_code, ndc, value, ...) are not mis-typed
    by the sniffer.

    patients/admissions/transfers exist in both core/ and hosp/. Prefer hosp/.
#}
{% macro read_mimic4(table, module, varchar_cols=[], sample_size=200000) %}
    read_csv_auto(
        '{{ var("mimic4_path") }}/{{ module }}/{{ table }}.csv.gz'
        , header = true
        , sample_size = {{ sample_size }}
        , all_varchar = false
        {%- if varchar_cols and varchar_cols | length > 0 %}
        , types = { {% for c in varchar_cols %}'{{ c }}': 'VARCHAR'{% if not loop.last %}, {% endif %}{% endfor %} }
        {%- endif %}
    )
{%- endmacro %}
