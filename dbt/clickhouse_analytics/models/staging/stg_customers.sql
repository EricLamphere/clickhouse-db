{{
    config(
        materialized='view',
        tags=['staging', 'customers']
    )
}}

with source as (
    select * from {{ source('staging', 'customers') }}
),

renamed as (
    select
        -- Primary key
        customer_id,

        -- Attributes
        customer_name,
        email,
        country,
        signup_date,
        is_active,

        -- Derived fields
        case
            when is_active = 1 then true
            else false
        end as is_active_flag,

        -- Metadata
        now() as loaded_at

    from source
)

select * from renamed
