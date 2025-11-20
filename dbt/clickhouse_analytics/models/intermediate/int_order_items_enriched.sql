{{
    config(
        materialized='view',
        tags=['intermediate']
    )
}}

with order_items as (
    select * from {{ ref('stg_order_items') }}
),

orders as (
    select * from {{ ref('stg_orders') }}
),

products as (
    select * from {{ ref('stg_products') }}
),

enriched as (
    select
        -- Order item details
        oi.order_item_id,
        oi.order_id,
        oi.product_id,
        oi.quantity,
        oi.unit_price,
        oi.discount_percent,
        oi.line_total,

        -- Order details
        o.customer_id,
        o.order_date,
        o.order_timestamp,
        o.status as order_status,
        o.order_hour,
        o.order_day_of_week,
        o.order_week,
        o.order_month,
        o.order_year,

        -- Product details
        p.product_name,
        p.category,
        p.cost as product_cost,

        -- Calculated metrics
        oi.quantity * p.cost as line_cost,
        oi.line_total - (oi.quantity * p.cost) as line_profit,
        case
            when oi.line_total > 0 then
                (oi.line_total - (oi.quantity * p.cost)) / oi.line_total
            else 0
        end as line_profit_margin_pct

    from order_items oi
    inner join orders o on oi.order_id = o.order_id
    inner join products p on oi.product_id = p.product_id
)

select * from enriched
