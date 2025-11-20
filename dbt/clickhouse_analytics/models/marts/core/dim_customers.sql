{{
    config(
        materialized='table',
        tags=['marts', 'core'],
        order_by='customer_id',
        engine='MergeTree()'
    )
}}

with customers as (
    select * from {{ ref('stg_customers') }}
),

customer_orders as (
    select
        customer_id,
        count(distinct order_id) as total_orders,
        sum(case when status = 'completed' then 1 else 0 end) as completed_orders,
        sum(case when status = 'cancelled' then 1 else 0 end) as cancelled_orders,
        sum(case when status = 'completed' then total_amount else 0 end) as lifetime_value,
        min(order_date) as first_order_date,
        max(order_date) as last_order_date,
        avg(case when status = 'completed' then total_amount else null end) as avg_order_value

    from {{ ref('stg_orders') }}
    group by customer_id
),

final as (
    select
        -- Customer identifiers
        c.customer_id,

        -- Customer attributes
        c.customer_name,
        c.email,
        c.country,
        c.signup_date,
        c.is_active_flag,

        -- Order metrics
        coalesce(co.total_orders, 0) as total_orders,
        coalesce(co.completed_orders, 0) as completed_orders,
        coalesce(co.cancelled_orders, 0) as cancelled_orders,
        coalesce(co.lifetime_value, 0) as lifetime_value,
        co.first_order_date,
        co.last_order_date,
        coalesce(co.avg_order_value, 0) as avg_order_value,

        -- Calculated metrics
        case
            when co.first_order_date is not null then
                dateDiff('day', co.first_order_date, co.last_order_date)
            else 0
        end as customer_tenure_days,

        case
            when co.last_order_date is not null then
                dateDiff('day', co.last_order_date, today())
            else null
        end as days_since_last_order,

        case
            when coalesce(co.lifetime_value, 0) >= {{ var('high_value_threshold') }} then true
            else false
        end as is_high_value_customer,

        -- Metadata
        now() as _loaded_at

    from customers c
    left join customer_orders co on c.customer_id = co.customer_id
)

select * from final
