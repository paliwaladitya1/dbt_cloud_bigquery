-- snapshots/snap_orders.sql
-- SCD Type 2 snapshot for orders.
-- A new version row is created whenever any tracked column changes.
-- dbt adds: dbt_scd_id, dbt_updated_at, dbt_valid_from, dbt_valid_to (null = current).

{% snapshot snap_orders %}

{{
    config(
        target_schema = 'snapshots',
        unique_key    = 'order_id',
        strategy      = 'check',
        check_cols    = [
            'status',
            'quantity',
            'unit_price',
            'discount_rate',
            'total_amount',
            'shipped_date',
            'shipping_country',
            'payment_method',
            'notes'
        ],
        invalidate_hard_deletes = true
    )
}}

select
    order_id,
    customer_id,
    product_id,
    customer_name,
    customer_email,
    product_name,
    category,
    order_date,
    shipped_date,
    status,
    quantity,
    unit_price,
    discount_rate,
    total_amount,
    payment_method,
    shipping_country,
    notes,
    _updated_at
from {{ ref('stg_orders') }}

{% endsnapshot %}
