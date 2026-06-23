-- models/marts/dim_orders_scd2.sql
-- SCD Type 2 order dimension built from the snap_orders snapshot.
-- Contains one row per version of each order. Use dbt_valid_to IS NULL to get current state.
-- Join to fct_orders on order_id + dbt_valid_from <= event_date < dbt_valid_to for point-in-time.

{{
    config(
        materialized = 'table',
        partition_by = {
            'field': 'valid_from',
            'data_type': 'timestamp',
            'granularity': 'month'
        },
        cluster_by = ['order_id', 'is_current']
    )
}}

with snapshot as (

    select * from {{ ref('snap_orders') }}

),

enriched as (

    select
        -- SCD2 surrogate key (unique per version row)
        dbt_scd_id                                                  as order_version_key,

        -- natural key
        order_id,

        -- foreign keys
        customer_id,
        product_id,

        -- SCD2 validity window
         dbt_valid_from                                              as valid_from,
         dbt_valid_to                                                as valid_to,
         dbt_valid_to is null                                        as is_current,

        -- version sequence within each order
        row_number() over (
            partition by order_id
            order by dbt_valid_from
        )                                                           as version_number,

        -- slowly changing attributes (what we track for history)
        status,
        quantity,
        unit_price,
        discount_rate,
        total_amount,
        shipped_date,
        shipping_country,
        payment_method,
        notes,

        -- static attributes (don't change, but carried for convenience)
        customer_name,
        customer_email,
        product_name,
        category,
        order_date,

        -- derived fields (recomputed per version)
        upper(
            case
                when payment_method in ('CREDIT_CARD', 'PAYPAL')   then 'consumer'
                when payment_method = 'BANK_TRANSFER'               then 'b2b'
                when payment_method = 'CRYPTO'                      then 'alternative'
                else 'other'
            end
        )                                                           as payment_channel,

        case
            when total_amount < 100                                 then 'small'
            when total_amount < 300                                 then 'medium'
            when total_amount < 600                                 then 'large'
            else 'enterprise'
        end                                                         as order_size_tier,

        -- flags (computed at each version point)
        status = 'DELIVERED'                                        as is_delivered,
        status = 'CANCELLED'                                        as is_cancelled,
        discount_rate > 0                                           as has_discount,
        date_diff(shipped_date, order_date, day)                    as days_to_ship,

        -- audit
        dbt_updated_at                                              as record_updated_at

    from snapshot

)

select * from enriched
