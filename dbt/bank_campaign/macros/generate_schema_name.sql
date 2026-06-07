{#
    Use the configured `+schema` value as the LITERAL BigQuery dataset name
    (e.g. `staging`, `marts`) instead of dbt's default behaviour of prefixing
    it with the target schema (which would produce `raw_staging`, etc.).

    When a model sets no custom schema, fall back to the profile's default
    dataset (`raw`).
#}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- set default_schema = target.schema -%}
    {%- if custom_schema_name is none -%}
        {{ default_schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
