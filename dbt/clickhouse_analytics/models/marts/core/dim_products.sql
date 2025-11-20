{{
    config(
        materialized='table',
        tags=['marts', 'core'],
        order_by='product_id',
        engine='MergeTree()'
    )
}}

with products as (
    select * from {{ ref('stg_products') }}
),

product_sales as (
    select
        product_id,
        count(distinct order_id) as times_ordered,
        sum(quantity) as total_quantity_sold,
        sum(line_total) as total_revenue,
        sum(line_profit) as total_profit,
        avg(line_total / quantity) as avg_selling_price

    from {{ ref('int_order_items_enriched') }}
    where order_status = 'completed'
    group by product_id
),

final as (
    select
        -- Product identifiers
        p.product_id,

        -- Product attributes
        p.product_name,
        p.category,
        p.price,
        p.cost,
        p.profit_margin,
        p.profit_margin_pct,
        p.created_at,

        -- Sales metrics
        coalesce(ps.times_ordered, 0) as times_ordered,
        coalesce(ps.total_quantity_sold, 0) as total_quantity_sold,
        coalesce(ps.total_revenue, 0) as total_revenue,
        coalesce(ps.total_profit, 0) as total_profit,
        coalesce(ps.avg_selling_price, p.price) as avg_selling_price,

        -- Calculated metrics
        case
            when ps.total_revenue > 0 then
                ps.total_profit / ps.total_revenue
            else p.profit_margin_pct
        end as realized_profit_margin_pct,

        -- Metadata
        now() as _loaded_at

    from products p
    left join product_sales ps on p.product_id = ps.product_id
)

select * from final
