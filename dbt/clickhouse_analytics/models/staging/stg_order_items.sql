{{
    config(
        materialized='view',
        tags=['staging', 'order_items']
    )
}}

with source as (
    select * from {{ source('staging', 'order_items') }}
),

renamed as (
    select
        -- Primary key
        order_item_id,

        -- Foreign keys
        order_id,
        product_id,

        -- Attributes
        quantity,
        unit_price,
        discount_percent,

        -- Derived metrics
        quantity * unit_price as line_total_before_discount,
        (quantity * unit_price) * (discount_percent / 100) as discount_amount,
        (quantity * unit_price) - ((quantity * unit_price) * (discount_percent / 100)) as line_total,

        -- Metadata
        now() as loaded_at

    from source
)

select * from renamed
