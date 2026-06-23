-- models/intermediate/int_orders_enriched.sql
-- Intermediate layer: derived fields, business flags, and classifications.
-- Consumes staging; feeds mart models.

with stg as (

    select * from {{ ref('stg_orders') }}

),

enriched as (

    select
        -- pass-through identifiers
        order_id,
        customer_id,
        product_id,

        -- pass-through dimensions
        customer_name,
        customer_email,
        product_name,
        category,
        payment_method,
        shipping_country,
        status,
        notes,

        -- dates
        order_date,
        shipped_date,

        -- derived date fields
        date_trunc(order_date, month)                               as order_month,
        extract(year  from order_date)                              as order_year,
        extract(quarter from order_date)                            as order_quarter,

        -- fulfillment metrics
        date_diff(shipped_date, order_date, day)                    as days_to_ship,

        -- financials
        quantity,
        unit_price,
        discount_rate,
        round(unit_price * discount_rate, 2)                        as discount_amount,
        total_amount,
        round(total_amount / nullif(quantity, 0), 2)                as revenue_per_unit,

        -- business flags
        case
            when status = 'DELIVERED'                               then true
            else false
        end                                                         as is_delivered,

        case
            when status = 'CANCELLED'                               then true
            else false
        end                                                         as is_cancelled,

        case
            when shipped_date is null
             and status not in ('CANCELLED', 'PENDING')             then true
            else false
        end                                                         as is_unshipped_active,

        case
            when discount_rate > 0                                  then true
            else false
        end                                                         as has_discount,

        -- order size bucket
        case
            when total_amount < 100                                 then 'small'
            when total_amount between 100 and 299.99                then 'medium'
            when total_amount between 300 and 599.99                then 'large'
            else 'enterprise'
        end                                                         as order_size_tier,

        -- payment channel type
        case
            when payment_method in ('CREDIT_CARD', 'PAYPAL')       then 'consumer'
            when payment_method in ('BANK_TRANSFER')                then 'b2b'
            when payment_method in ('CRYPTO')                       then 'alternative'
            else 'other'
        end                                                         as payment_channel

    from stg

)

select * from enriched
