{{
    config(
        materialized='view',
        tags=['staging', 'orders']
    )
}}

with source as (
    select * from {{ source('staging', 'orders') }}
),

renamed as (
    select
        -- Primary key
        order_id,

        -- Foreign keys
        customer_id,

        -- Attributes
        order_date,
        order_timestamp,
        total_amount,
        status,

        -- Derived fields
        toHour(order_timestamp) as order_hour,
        toDayOfWeek(order_date) as order_day_of_week,
        toStartOfWeek(order_date) as order_week,
        toStartOfMonth(order_date) as order_month,
        toQuarter(order_date) as order_quarter,
        toYear(order_date) as order_year,

        -- Status flags
        case when status = 'completed' then 1 else 0 end as is_completed,
        case when status = 'cancelled' then 1 else 0 end as is_cancelled,

        -- Metadata
        now() as loaded_at

    from source
)

select * from renamed
