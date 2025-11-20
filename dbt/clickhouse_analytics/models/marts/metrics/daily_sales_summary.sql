{{
    config(
        materialized='table',
        tags=['marts', 'metrics'],
        order_by='sales_date',
        partition_by='toYYYYMM(sales_date)',
        engine='MergeTree()'
    )
}}

with daily_orders as (
    select
        order_date as sales_date,
        count(distinct order_id) as total_orders,
        count(distinct case when status = 'completed' then order_id end) as completed_orders,
        count(distinct customer_id) as unique_customers,
        sum(case when status = 'completed' then total_revenue else 0 end) as total_revenue,
        sum(case when status = 'completed' then total_cost else 0 end) as total_cost,
        sum(case when status = 'completed' then total_profit else 0 end) as total_profit,
        sum(case when status = 'completed' then total_items else 0 end) as total_items_sold,
        avg(case when status = 'completed' then total_revenue else null end) as avg_order_value

    from {{ ref('fct_orders') }}
    group by order_date
),

final as (
    select
        sales_date,
        total_orders,
        completed_orders,
        unique_customers,
        total_revenue,
        total_cost,
        total_profit,
        total_items_sold,
        avg_order_value,

        -- Calculated metrics
        case
            when total_revenue > 0 then total_profit / total_revenue
            else 0
        end as profit_margin_pct,

        case
            when completed_orders > 0 then total_revenue / completed_orders
            else 0
        end as revenue_per_completed_order,

        -- Metadata
        now() as _loaded_at

    from daily_orders
)

select * from final
