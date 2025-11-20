-- Create tables in Postgres that will be replicated to ClickHouse
-- using MaterializedPostgreSQL engine

-- Enable logical replication (required for MaterializedPostgreSQL)
ALTER SYSTEM SET wal_level = logical;

-- Create schema for source data
CREATE SCHEMA IF NOT EXISTS source;

-- User activity tracking table
CREATE TABLE IF NOT EXISTS source.user_activities (
    activity_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    activity_type VARCHAR(50) NOT NULL,
    activity_timestamp TIMESTAMP NOT NULL DEFAULT NOW(),
    session_id VARCHAR(100),
    page_url VARCHAR(500),
    duration_seconds INTEGER,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Create index for better query performance
CREATE INDEX idx_user_activities_user_id ON source.user_activities(user_id);
CREATE INDEX idx_user_activities_timestamp ON source.user_activities(activity_timestamp);

-- Inventory table that changes frequently (good candidate for replication)
CREATE TABLE IF NOT EXISTS source.inventory (
    inventory_id SERIAL PRIMARY KEY,
    product_id INTEGER NOT NULL,
    warehouse_location VARCHAR(100) NOT NULL,
    quantity_available INTEGER NOT NULL DEFAULT 0,
    quantity_reserved INTEGER NOT NULL DEFAULT 0,
    last_restocked_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_inventory_product_id ON source.inventory(product_id);

-- Payment transactions table
CREATE TABLE IF NOT EXISTS source.payment_transactions (
    transaction_id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL,
    payment_method VARCHAR(50) NOT NULL,
    transaction_amount DECIMAL(10, 2) NOT NULL,
    transaction_status VARCHAR(20) NOT NULL,
    transaction_timestamp TIMESTAMP NOT NULL DEFAULT NOW(),
    processor_response TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_payment_transactions_order_id ON source.payment_transactions(order_id);
CREATE INDEX idx_payment_transactions_timestamp ON source.payment_transactions(transaction_timestamp);

-- Create a publication for replication
-- This allows ClickHouse to subscribe to changes
CREATE PUBLICATION clickhouse_publication FOR ALL TABLES;

-- Create a replication slot (ClickHouse will use this)
-- Note: This will be created by ClickHouse when it connects
