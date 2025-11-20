-- Create staging tables for CSV data
CREATE TABLE IF NOT EXISTS staging.customers
(
    customer_id UInt32,
    customer_name String,
    email String,
    country String,
    signup_date Date,
    is_active UInt8
)
ENGINE = MergeTree()
ORDER BY customer_id
SETTINGS index_granularity = 8192;

CREATE TABLE IF NOT EXISTS staging.products
(
    product_id UInt32,
    product_name String,
    category String,
    price Decimal(10, 2),
    cost Decimal(10, 2),
    created_at DateTime
)
ENGINE = MergeTree()
ORDER BY product_id
SETTINGS index_granularity = 8192;

CREATE TABLE IF NOT EXISTS staging.orders
(
    order_id UInt32,
    customer_id UInt32,
    order_date Date,
    order_timestamp DateTime,
    total_amount Decimal(10, 2),
    status String
)
ENGINE = MergeTree()
PARTITION BY toYYYYMM(order_date)
ORDER BY (customer_id, order_date, order_id)
SETTINGS index_granularity = 8192;

CREATE TABLE IF NOT EXISTS staging.order_items
(
    order_item_id UInt32,
    order_id UInt32,
    product_id UInt32,
    quantity UInt16,
    unit_price Decimal(10, 2),
    discount_percent Decimal(5, 2)
)
ENGINE = MergeTree()
ORDER BY (order_id, order_item_id)
SETTINGS index_granularity = 8192;
