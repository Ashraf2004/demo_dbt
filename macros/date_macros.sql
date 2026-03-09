{% macro date_spine(start_date, end_date) %}
    with date_spine as (
        {{ dbt_utils.date_spine(
            datepart="day",
            start_date="cast('" ~ start_date ~ "' as date)",
            end_date="cast('" ~ end_date ~ "' as date)"
        ) }}
    )
    select 
        date_day,
        dayname(date_day) as day_name,
        month(date_day) as month_num,
        year(date_day) as year_num
    from date_spine
{% endmacro %}

{% macro fiscal_year(date_column, fiscal_year_start_month=1) %}
    case 
        when month({{ date_column }}) >= {{ fiscal_year_start_month }}
        then year({{ date_column }})
        else year({{ date_column }}) - 1
    end
{% endmacro %}

#check this
