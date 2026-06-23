-- macros/scd2_point_in_time.sql
-- Reusable macro to filter an SCD2 model to a specific point in time.
--
-- Usage in a model:
--   {{ scd2_point_in_time(ref('dim_customers_scd2'), 'valid_from', 'valid_to', 'order_date') }}
--
-- Arguments:
--   relation      — the SCD2 model ref
--   valid_from_col — column name for the start of validity (default: 'valid_from')
--   valid_to_col   — column name for the end of validity   (default: 'valid_to')
--   as_of_col      — the date/timestamp to look up against (can be a column or literal)

{% macro scd2_point_in_time(relation, valid_from_col='valid_from', valid_to_col='valid_to', as_of_col='current_timestamp()') %}

    select *
    from {{ relation }}
    where
        {{ valid_from_col }} <= {{ as_of_col }}
        and (
            {{ valid_to_col }} > {{ as_of_col }}
            or {{ valid_to_col }} is null
        )

{% endmacro %}
