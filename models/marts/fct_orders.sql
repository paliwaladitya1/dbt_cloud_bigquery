-- models/marts/fct_orders.sql
-- Fact table: one row per order. Final analytics-ready grain.
-- Materialized as a table for query performance.

{{
    config(
        materialized = 'table',
        partition_by = {
            'field': 'order_date',
            'data_type': 'date',
            'granularity': 'month'
        },
        cluster_by = ['status', 'category']
    )
}}

with orders as (

    select * from {{ ref('int_orders_enriched') }}

)

select
    -- surrogate key (use dbt_utils.generate_surrogate_key if available)
    order_id,

    -- foreign keys
    customer_id,
    product_id,

    -- dates
    order_date,
    shipped_date,
    order_month,
    order_year,
    order_quarter,

    -- dimensions
    status,
    category,
    payment_method,
    payment_channel,
    shipping_country,
    order_size_tier,

    -- product
    product_name,

    -- measures
    quantity,
    unit_price,
    discount_rate,
    discount_amount,
    total_amount,
    revenue_per_unit,
    days_to_ship,

    -- flags
    is_delivered,
    is_cancelled,
    is_unshipped_active,
    has_discount

from orders
