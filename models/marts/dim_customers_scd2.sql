-- models/marts/dim_customers_scd2.sql
-- SCD Type 2 customer dimension built from snap_customers.
-- Use is_current = true for the latest customer profile.
-- Use valid_from / valid_to for point-in-time lookups against order dates.

{{
    config(
        materialized = 'table',
        cluster_by   = ['customer_id', 'is_current']
    )
}}

with snapshot as (

    select * from {{ ref('snap_customers') }}

),

versioned as (

    select
        -- SCD2 surrogate key
        dbt_scd_id                                                  as customer_version_key,

        -- natural key
        customer_id,

        -- SCD2 validity window
        dbt_valid_from                                              as valid_from,
        dbt_valid_to                                                as valid_to,
        dbt_valid_to is null                                        as is_current,

        -- version sequence
        row_number() over (
            partition by customer_id
            order by dbt_valid_from
        )                                                           as version_number,

        -- slowly changing attributes
        customer_name,
        customer_email,
        customer_segment,
        ltv_tier,
        preferred_payment_method,

        -- metrics at the time of this version
        total_orders,
        delivered_orders,
        cancelled_orders,
        lifetime_revenue,
        avg_order_value,
        max_order_value,
        countries_shipped_to,
        payment_methods_used,
        categories_purchased,

        -- static dates
        first_order_date,
        last_order_date,
        customer_lifespan_days,

        -- audit
        dbt_updated_at                                              as record_updated_at

    from snapshot

)

select * from versioned
