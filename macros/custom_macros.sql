{% macro cents_to_dollars(column_name, scale=2) %}
    round({{ column_name }} / 100.0, {{ scale }})
{% endmacro %}

{% macro generate_alias_name(custom_alias_name=none, node=none) -%}
    {%- if custom_alias_name is none -%}
        {{ node.name }}
    {%- else -%}
        {{ custom_alias_name | trim }}
    {%- endif -%}
{%- endmacro %}

{% macro get_current_timestamp() %}
    {% if target.type == 'snowflake' %}
        current_timestamp()
    {% elif target.type == 'bigquery' %}
        current_timestamp()
    {% elif target.type == 'postgres' %}
        now()
    {% else %}
        current_timestamp
    {% endif %}
{% endmacro %}

{% macro clean_string(column_name) %}
    trim(upper({{ column_name }}))
{% endmacro %}
