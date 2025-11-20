{{
    config(
        materialized='table',
        tags=['marts', 'core'],
        order_by='(customer_id, order_date, order_id)',
        partition_by='toYYYYMM(order_date)',
        engine='MergeTree()'
    )
}}

with order_items_agg as (
    select
        order_id,
        sum(line_total) as total_revenue,
        sum(line_cost) as total_cost,
        sum(line_profit) as total_profit,
        count(distinct product_id) as distinct_products,
        sum(quantity) as total_items

    from {{ ref('int_order_items_enriched') }}
    group by order_id
),

orders as (
    select * from {{ ref('int_customer_orders') }}
),

final as (
    select
        -- Order identifiers
        o.order_id,
        o.customer_id,

        -- Customer attributes
        o.customer_name,
        o.email,
        o.country,
        o.customer_segment,

        -- Order attributes
        o.order_date,
        o.order_timestamp,
        o.status,
        o.order_month,
        o.order_year,

        -- Order metrics
        o.total_amount,
        oia.total_revenue,
        oia.total_cost,
        oia.total_profit,
        oia.distinct_products,
        oia.total_items,

        -- Calculated metrics
        case
            when oia.total_revenue > 0 then
                oia.total_profit / oia.total_revenue
            else 0
        end as profit_margin_pct,

        o.days_since_signup,

        -- Metadata
        now() as _loaded_at

    from orders o
    left join order_items_agg oia on o.order_id = oia.order_id
)

select * from final
