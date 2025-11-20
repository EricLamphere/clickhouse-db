-- Create main analytics database
CREATE DATABASE IF NOT EXISTS analytics;

-- Create staging database for raw data
CREATE DATABASE IF NOT EXISTS staging;

-- Create database for PostgreSQL materialized data
-- Note: MaterializedPostgreSQL requires special setup and will be created after Postgres is ready
-- This will be handled in a separate initialization script
