-- models/marts/agg_orders_by_month.sql
-- Monthly revenue and order aggregates for dashboards and reporting.

{{
    config(
        materialized = 'table'
    )
}}

with fct as (

    select * from {{ ref('fct_orders') }}

)

select
    order_month,
    order_year,
    order_quarter,
    category,
    shipping_country,

    -- volume
    count(*)                                                        as total_orders,
    sum(quantity)                                                   as total_units_sold,

    -- revenue
    round(sum(total_amount), 2)                                     as gross_revenue,
    round(sum(discount_amount), 2)                                  as total_discount_given,
    round(sum(total_amount) - sum(discount_amount), 2)              as net_revenue,
    round(avg(total_amount), 2)                                     as avg_order_value,

    -- fulfillment
    countif(is_delivered)                                           as delivered_orders,
    countif(is_cancelled)                                           as cancelled_orders,
    round(avg(case when days_to_ship is not null
                   then days_to_ship end), 1)                       as avg_days_to_ship,

    -- mix
    round(countif(is_cancelled) / count(*) * 100, 1)               as cancellation_rate_pct,
    round(countif(has_discount) / count(*) * 100, 1)               as discount_rate_pct

from fct
group by
    order_month,
    order_year,
    order_quarter,
    category,
    shipping_country
order by
    order_month,
    category
