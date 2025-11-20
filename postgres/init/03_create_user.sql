-- Create a user for ClickHouse replication
-- This user needs replication privileges

CREATE ROLE clickhouse_replication WITH REPLICATION LOGIN PASSWORD 'clickhouse_repl';
GRANT CONNECT ON DATABASE source_db TO clickhouse_replication;
GRANT USAGE ON SCHEMA source TO clickhouse_replication;
GRANT SELECT ON ALL TABLES IN SCHEMA source TO clickhouse_replication;
ALTER DEFAULT PRIVILEGES IN SCHEMA source GRANT SELECT ON TABLES TO clickhouse_replication;

-- Grant necessary privileges for replication
GRANT pg_read_all_data TO clickhouse_replication;
