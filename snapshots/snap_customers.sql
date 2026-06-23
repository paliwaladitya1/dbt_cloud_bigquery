-- snapshots/snap_customers.sql
-- SCD Type 2 snapshot for the customer dimension.
-- Captures changes to customer attributes (name, email, segment, ltv_tier).
-- Each change produces a new row; dbt_valid_to = null means the current record.

{% snapshot snap_customers %}

{{
    config(
        target_schema = 'snapshots',
        unique_key    = 'customer_id',
        strategy      = 'check',
        check_cols    = [
            'customer_name',
            'customer_email',
            'total_orders',
            'lifetime_revenue',
            'customer_segment',
            'ltv_tier',
            'preferred_payment_method',
            'countries_shipped_to'
        ],
        invalidate_hard_deletes = true
    )
}}

-- We snapshot the mart-level customer view so all derived attributes are versioned too.
-- If dim_customers hasn't been built yet, run: dbt run --select dim_customers first.
select
    customer_id,
    customer_name,
    customer_email,
    total_orders,
    delivered_orders,
    cancelled_orders,
    lifetime_revenue,
    avg_order_value,
    max_order_value,
    first_order_date,
    last_order_date,
    customer_lifespan_days,
    countries_shipped_to,
    payment_methods_used,
    categories_purchased,
    preferred_payment_method,
    customer_segment,
    ltv_tier,
    current_timestamp()     as _updated_at
from {{ ref('dim_customers') }}

{% endsnapshot %}
