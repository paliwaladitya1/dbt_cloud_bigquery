-- models/intermediate/int_orders_enriched.sql
-- Intermediate layer: derived fields, business flags, classifications.
-- _updated_at is passed through so snapshots can detect changes via check strategy.

with stg as (

    select * from {{ ref('stg_orders') }}

),

enriched as (

    select
        -- identifiers
        order_id,
        customer_id,
        product_id,

        -- dimensions
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
        date_trunc(order_date, month)                               as order_month,
        extract(year    from order_date)                            as order_year,
        extract(quarter from order_date)                            as order_quarter,

        -- fulfillment
        date_diff(shipped_date, order_date, day)                    as days_to_ship,

        -- financials
        quantity,
        unit_price,
        discount_rate,
        round(unit_price * discount_rate, 2)                        as discount_amount,
        total_amount,
        round(total_amount / nullif(quantity, 0), 2)                as revenue_per_unit,

        -- business flags
        status = 'DELIVERED'                                        as is_delivered,
        status = 'CANCELLED'                                        as is_cancelled,
        (shipped_date is null
          and status not in ('CANCELLED', 'PENDING'))               as is_unshipped_active,
        discount_rate > 0                                           as has_discount,

        -- order size tier
        case
            when total_amount < 100                                 then 'small'
            when total_amount < 300                                 then 'medium'
            when total_amount < 600                                 then 'large'
            else 'enterprise'
        end                                                         as order_size_tier,

        -- payment channel
        case
            when payment_method in ('CREDIT_CARD', 'PAYPAL')       then 'consumer'
            when payment_method = 'BANK_TRANSFER'                   then 'b2b'
            when payment_method = 'CRYPTO'                          then 'alternative'
            else 'other'
        end                                                         as payment_channel,

        -- SCD2 watermark — propagated from source
        _updated_at

    from stg

)

select * from enriched
