{{
    config(
        materialized='view',
        tags=['intermediate']
    )
}}

with orders as (
    select * from {{ ref('stg_orders') }}
),

customers as (
    select * from {{ ref('stg_customers') }}
),

customer_orders as (
    select
        -- Customer details
        c.customer_id,
        c.customer_name,
        c.email,
        c.country,
        c.signup_date,
        c.is_active_flag,

        -- Order details
        o.order_id,
        o.order_date,
        o.order_timestamp,
        o.total_amount,
        o.status,
        o.order_month,
        o.order_year,

        -- Calculated fields
        dateDiff('day', c.signup_date, o.order_date) as days_since_signup,
        case
            when dateDiff('day', c.signup_date, o.order_date) <= 30 then 'New'
            when dateDiff('day', c.signup_date, o.order_date) <= 90 then 'Regular'
            else 'Loyal'
        end as customer_segment

    from customers c
    inner join orders o on c.customer_id = o.customer_id
)

select * from customer_orders
