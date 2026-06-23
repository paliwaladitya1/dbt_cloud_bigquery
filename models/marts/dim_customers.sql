-- models/marts/dim_customers.sql
-- Customer dimension: one row per customer with lifetime aggregates.

{{
    config(
        materialized = 'table'
    )
}}

with orders as (

    select * from {{ ref('int_orders_enriched') }}

),

-- 1. Calculate the preferred payment method cleanly in its own step
preferred_payments as (

    select
        customer_id,
        payment_method
    from orders
    where payment_method is not null
    group by customer_id, payment_method
    qualify row_number() over (
        partition by customer_id 
        order by count(*) desc, max(order_date) desc
    ) = 1

),

customer_aggregates as (

    select
        customer_id,
        customer_name,
        customer_email,

        -- order history
        count(*)                                                    as total_orders,
        count(case when is_delivered then 1 end)                    as delivered_orders,
        count(case when is_cancelled then 1 end)                    as cancelled_orders,

        -- revenue
        round(sum(total_amount), 2)                                 as lifetime_revenue,
        round(avg(total_amount), 2)                                 as avg_order_value,
        round(max(total_amount), 2)                                 as max_order_value,

        -- dates
        min(order_date)                                             as first_order_date,
        max(order_date)                                             as last_order_date,
        date_diff(max(order_date), min(order_date), day)            as customer_lifespan_days,

        -- behaviour flags
        count(distinct shipping_country)                            as countries_shipped_to,
        count(distinct payment_method)                              as payment_methods_used,
        count(distinct category)                                    as categories_purchased

    from orders
    group by customer_id, customer_name, customer_email

),

-- 2. Join the aggregates and the preferred payment method together
customer_orders as (

    select
        a.*,
        p.payment_method as preferred_payment_method
    from customer_aggregates a
    left join preferred_payments p 
        on a.customer_id = p.customer_id

),

final as (

    select
        *,

        -- customer segment
        case
            when total_orders = 1                                   then 'one_time'
            when total_orders between 2 and 4                       then 'repeat'
            else 'loyal'
        end                                                         as customer_segment,

        -- ltv tier
        case
            when lifetime_revenue < 200                             then 'low'
            when lifetime_revenue between 200 and 599.99            then 'mid'
            else 'high'
        end                                                         as ltv_tier

    from customer_orders

)

select * from final