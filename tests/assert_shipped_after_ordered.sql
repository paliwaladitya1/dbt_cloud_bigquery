-- tests/assert_shipped_after_ordered.sql
-- Singular test: shipped_date must never be before order_date

select
    order_id,
    order_date,
    shipped_date
from {{ ref('fct_orders') }}
where shipped_date is not null
  and shipped_date < order_date
