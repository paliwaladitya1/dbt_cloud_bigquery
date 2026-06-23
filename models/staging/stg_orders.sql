-- models/staging/stg_orders.sql
-- Staging layer: cast types, rename fields, light cleaning only. No business logic.

with source as (

    select * from {{ source('sales', 'orders') }}

),

renamed as (

    select
        -- identifiers
        order_id,
        customer_id,
        product_id,

        -- customer info
        customer_name,
        lower(trim(customer_email))                         as customer_email,

        -- product info
        product_name,
        category,

        -- dates
        order_date,
        shipped_date,

        -- order lifecycle
        upper(trim(status))                                 as status,

        -- financials
        cast(quantity   as int64)                           as quantity,
        cast(unit_price as numeric)                         as unit_price,
        cast(discount   as numeric)                         as discount_rate,     -- e.g. 0.10 = 10%
        cast(total_amount as numeric)                       as total_amount,

        -- payment & shipping
        upper(trim(payment_method))                         as payment_method,
        trim(shipping_country)                              as shipping_country,

        -- metadata
        notes,

        -- audit columns (add if your source has them)
        -- _loaded_at,
        -- _row_number

    from source

)

select * from renamed
