-- models/marts/fct_orders_point_in_time.sql
-- Example: join each order to the customer profile that was CURRENT at order_date.
-- Demonstrates point-in-time (bi-temporal) lookup using the scd2_point_in_time macro.
-- Useful for audits, backfills, or replaying historical state.

{{
    config(
        materialized = 'table',
        partition_by = {
            'field': 'order_date',
            'data_type': 'date',
            'granularity': 'month'
        }
    )
}}

with orders as (

    -- All order versions (not just current) for a full historical picture
    select * from {{ ref('dim_orders_scd2') }}

),

/*
    Point-in-time customer lookup:
    For each order, retrieve the customer segment + LTV tier that was
    active on the order_date — not necessarily the current values.
    This is the key SCD2 bi-temporal pattern.
*/
customers_pit as (

    select
        customer_id,
        customer_name,
        customer_email,
        customer_segment,
        ltv_tier,
        lifetime_revenue,
        total_orders,
        valid_from,
        valid_to
    from {{ ref('dim_customers_scd2') }}

)

select
    -- order identity
    o.order_id,
    o.order_version_key,
    o.version_number                                                as order_version,
    o.customer_id,

    -- order facts
    o.order_date,
    o.status,
    o.total_amount,
    o.category,
    o.product_name,
    o.quantity,
    o.unit_price,
    o.discount_rate,
    o.payment_method,
    o.shipping_country,

    -- order SCD2 window
    o.valid_from                                                    as order_valid_from,
    o.valid_to                                                      as order_valid_to,
    o.is_current                                                    as is_current_order_version,

    -- customer as-of order_date (point-in-time)
    c.customer_name                                                 as customer_name_at_order,
    c.customer_segment                                              as customer_segment_at_order,
    c.ltv_tier                                                      as ltv_tier_at_order,
    c.lifetime_revenue                                              as customer_ltv_at_order,
    c.total_orders                                                  as customer_orders_at_order

from orders o
left join customers_pit c
    on  o.customer_id = c.customer_id
    -- point-in-time join: customer record valid during the order date
    and cast(o.order_date as timestamp) >= c.valid_from
    and (
        cast(o.order_date as timestamp) < c.valid_to
        or c.valid_to is null
    )
