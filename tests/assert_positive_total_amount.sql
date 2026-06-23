-- tests/assert_positive_total_amount.sql
-- Singular test: total_amount must always be >= 0

select
    order_id,
    total_amount
from {{ ref('fct_orders') }}
where total_amount < 0
