{{
    config(
        materialized='view',
        tags=['staging', 'products']
    )
}}

with source as (
    select * from {{ source('staging', 'products') }}
),

renamed as (
    select
        -- Primary key
        product_id,

        -- Attributes
        product_name,
        category,
        price,
        cost,
        created_at,

        -- Derived metrics
        price - cost as profit_margin,
        (price - cost) / price as profit_margin_pct,

        -- Metadata
        now() as loaded_at

    from source
)

select * from renamed
