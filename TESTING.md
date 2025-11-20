# Testing & Validation Guide

Comprehensive guide to testing and validating the data pipeline.

## Quick Validation

Run this after setup to verify everything works:

```bash
# 1. Check all services are healthy
task status

# 2. Validate data loaded correctly
task validate-data

# 3. Test database connections
task clickhouse-test
task postgres-test

# 4. Trigger test DAG in Airflow
task airflow-test-dag
```

Expected result: All checks pass with green status.

## Service Health Checks

### Docker Services

```bash
# Check all containers are running
docker compose ps

# Expected output:
# clickhouse_server    - healthy
# clickhouse_postgres  - healthy
# airflow_postgres     - healthy
# airflow_webserver    - healthy
# airflow_scheduler    - healthy
```

### ClickHouse Health

```bash
# Test connection
task clickhouse-query -- "SELECT 1"

# Check version
task clickhouse-query -- "SELECT version()"

# Verify databases exist
task clickhouse-query -- "SHOW DATABASES"

# Expected databases: analytics, staging, system, default
```

### PostgreSQL Health

```bash
# Test connection
task postgres-query -- "SELECT 1"

# Check version
task postgres-query -- "SELECT version()"

# Verify schemas exist
task postgres-query -- "\dn"

# Expected schemas: public, source
```

### Airflow Health

```bash
# Check webserver is responding
curl -f http://localhost:8080/health

# List DAGs
task airflow-list-dags

# Expected DAGs:
# - clickhouse_analytics_pipeline
# - test_connections
```

## Data Validation Tests

### ClickHouse Staging Data

```bash
task clickhouse-client
```

```sql
-- Check table row counts
SELECT
    'customers' as table_name,
    count(*) as row_count
FROM staging.customers
UNION ALL
SELECT 'products', count(*) FROM staging.products
UNION ALL
SELECT 'orders', count(*) FROM staging.orders
UNION ALL
SELECT 'order_items', count(*) FROM staging.order_items
FORMAT Pretty;

-- Expected:
-- customers: 15
-- products: 15
-- orders: 20
-- order_items: 32

-- Verify data quality
SELECT
    count(*) as total_customers,
    count(DISTINCT customer_id) as unique_customers,
    count(DISTINCT country) as countries,
    sum(is_active) as active_customers
FROM staging.customers;

-- Expected: 15 total, 15 unique, 6 countries, ~13 active

-- Check for nulls in critical fields
SELECT
    countIf(customer_id IS NULL) as null_customer_ids,
    countIf(email IS NULL) as null_emails,
    countIf(signup_date IS NULL) as null_signup_dates
FROM staging.customers;

-- Expected: All zeros
```

### PostgreSQL Source Data

```bash
task postgres-client
```

```sql
-- Check table row counts
SELECT 'user_activities' as table_name, count(*) as row_count
FROM source.user_activities
UNION ALL
SELECT 'inventory', count(*) FROM source.inventory
UNION ALL
SELECT 'payment_transactions', count(*) FROM source.payment_transactions;

-- Expected: 10 rows in each table

-- Verify data quality
SELECT
    count(*) as total_activities,
    count(DISTINCT user_id) as unique_users,
    count(DISTINCT activity_type) as activity_types
FROM source.user_activities;

-- Expected: 10 total, 5 users, multiple types

-- Check for nulls
SELECT
    count(*) FILTER (WHERE user_id IS NULL) as null_user_ids,
    count(*) FILTER (WHERE activity_timestamp IS NULL) as null_timestamps
FROM source.user_activities;

-- Expected: All zeros
```

## dbt Testing

### Run All Tests

```bash
cd dbt/clickhouse_analytics

# Run all tests
dbt test --profiles-dir ../

# Expected: All tests pass
```

### Test Categories

**Schema Tests** (defined in .yml files):
- Unique constraints on primary keys
- Not null on required fields
- Relationship tests (foreign keys)
- Accepted values for enum fields

**Run Specific Test Types:**

```bash
# Unique tests only
dbt test --select test_type:unique --profiles-dir ../

# Not null tests only
dbt test --select test_type:not_null --profiles-dir ../

# Relationship tests only
dbt test --select test_type:relationships --profiles-dir ../

# Tests for specific model
dbt test --select stg_customers --profiles-dir ../
```

### Custom Data Quality Tests

Create in `tests/` directory:

```sql
-- tests/assert_positive_prices.sql
SELECT *
FROM {{ ref('stg_products') }}
WHERE price <= 0
```

Run: `dbt test --profiles-dir ../`

## Model Validation

### Compile Models

```bash
task dbt-compile

# Expected: All models compile successfully
# Check compiled SQL in target/compiled/
```

### Run Models Incrementally

```bash
# Staging only
dbt run --select staging --profiles-dir ../

# Intermediate only
dbt run --select intermediate --profiles-dir ../

# Marts only
dbt run --select marts --profiles-dir ../

# Specific model and downstream
dbt run --select stg_customers+ --profiles-dir ../
```

### Verify Model Output

```bash
task clickhouse-client
```

```sql
-- Check marts were created
SHOW TABLES FROM analytics_marts;

-- Expected tables:
-- - dim_customers
-- - dim_products
-- - fct_orders
-- - daily_sales_summary

-- Validate dim_customers
SELECT
    count(*) as total_customers,
    avg(lifetime_value) as avg_ltv,
    sum(is_high_value_customer) as high_value_count
FROM analytics_marts.dim_customers;

-- Validate fct_orders
SELECT
    count(*) as total_orders,
    avg(total_revenue) as avg_order_value,
    avg(profit_margin_pct) as avg_margin
FROM analytics_marts.fct_orders;

-- Validate daily_sales_summary
SELECT *
FROM analytics_marts.daily_sales_summary
ORDER BY sales_date DESC
LIMIT 5;
```

## Airflow Pipeline Testing

### Test Connection DAG

```bash
# Trigger test connections DAG
task airflow-test-dag

# Monitor in UI: http://localhost:8080
# All tasks should succeed:
# - test_clickhouse_connection
# - test_postgres_connection
# - test_clickhouse_data
# - test_postgres_data
```

### Test Analytics Pipeline DAG

```bash
# Trigger main analytics pipeline
task airflow-analytics-dag

# Monitor in UI
# All tasks should succeed:
# - check_clickhouse_connection
# - verify_source_data
# - dbt_analytics (task group with all models)
```

### Check Task Logs

In Airflow UI:
1. Click on DAG
2. Click on task
3. View Logs tab

Or via CLI:
```bash
task logs-airflow
```

## Performance Testing

### Query Performance

```bash
task clickhouse-client
```

```sql
-- Enable query profiling
SET send_logs_level = 'trace';

-- Test simple query
SELECT count(*) FROM staging.orders;

-- Test complex join
SELECT
    c.customer_name,
    count(DISTINCT o.order_id) as order_count,
    sum(o.total_amount) as total_spent
FROM staging.customers c
LEFT JOIN staging.orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_name
ORDER BY total_spent DESC;

-- Check query log
SELECT
    query,
    query_duration_ms,
    read_rows,
    read_bytes
FROM system.query_log
WHERE type = 'QueryFinish'
ORDER BY event_time DESC
LIMIT 5;
```

### dbt Performance

```bash
# Run with timing
dbt run --profiles-dir ../ --log-level debug

# Check logs/dbt.log for execution times
grep "PASS" dbt/clickhouse_analytics/logs/dbt.log

# Expected: All models complete in < 1 second for sample data
```

## Integration Testing

### End-to-End Test

1. **Clear existing marts:**
```sql
-- In ClickHouse
DROP TABLE IF EXISTS analytics_marts.dim_customers;
DROP TABLE IF EXISTS analytics_marts.dim_products;
DROP TABLE IF EXISTS analytics_marts.fct_orders;
DROP TABLE IF EXISTS analytics_marts.daily_sales_summary;
```

2. **Run full pipeline:**
```bash
task airflow-analytics-dag
```

3. **Verify results:**
```sql
-- Check all marts were created
SHOW TABLES FROM analytics_marts;

-- Verify row counts
SELECT
    (SELECT count(*) FROM analytics_marts.dim_customers) as customers,
    (SELECT count(*) FROM analytics_marts.dim_products) as products,
    (SELECT count(*) FROM analytics_marts.fct_orders) as orders,
    (SELECT count(*) FROM analytics_marts.daily_sales_summary) as daily_summary;
```

### Data Lineage Test

Verify data flows correctly:

```sql
-- Count source records
SELECT count(*) FROM staging.customers;  -- 15

-- Count in staging model
SELECT count(*) FROM analytics_staging.stg_customers;  -- Should be 15

-- Count in mart
SELECT count(*) FROM analytics_marts.dim_customers;  -- Should be 15

-- Verify enrichment happened
SELECT
    customer_id,
    lifetime_value,
    total_orders,
    is_high_value_customer
FROM analytics_marts.dim_customers
WHERE total_orders > 0
LIMIT 5;
```

## Error Testing

### Test Error Handling

**Simulate connection failure:**
```bash
# Stop ClickHouse
docker compose stop clickhouse

# Try to run dbt
task dbt-run

# Expected: Graceful error message, no crash

# Restart
docker compose start clickhouse
```

**Simulate data quality failure:**
```sql
-- Insert invalid data
INSERT INTO staging.customers
VALUES (9999, 'Test User', NULL, 'USA', today(), 1);

-- Run tests
dbt test --select stg_customers --profiles-dir ../

-- Expected: Test failure on null email

-- Clean up
DELETE FROM staging.customers WHERE customer_id = 9999;
```

## Regression Testing

### Create Test Baseline

```bash
# Export current mart data
task clickhouse-client

-- Save baseline
SELECT * FROM analytics_marts.dim_customers
ORDER BY customer_id
INTO OUTFILE '/tmp/dim_customers_baseline.csv'
FORMAT CSV;
```

### Compare After Changes

```bash
# After making changes, export again
SELECT * FROM analytics_marts.dim_customers
ORDER BY customer_id
INTO OUTFILE '/tmp/dim_customers_current.csv'
FORMAT CSV;

# Compare files
diff /tmp/dim_customers_baseline.csv /tmp/dim_customers_current.csv
```

## Continuous Testing

### Pre-commit Checks

Before committing code:

```bash
# 1. Compile all models
task dbt-compile

# 2. Run all tests
task dbt-test

# 3. Check DAG validity
docker compose exec airflow-webserver airflow dags list

# 4. Validate YAML syntax
python -c "import yaml; yaml.safe_load(open('docker-compose.yml'))"
```

### CI/CD Testing (Future)

Set up GitHub Actions:
```yaml
# .github/workflows/test.yml
name: Test Pipeline
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Start services
        run: docker compose up -d
      - name: Wait for health
        run: sleep 60
      - name: Run tests
        run: |
          docker compose exec airflow-webserver dbt test --profiles-dir /opt/airflow/dbt
```

## Troubleshooting Tests

### Test Failures

**dbt test fails:**
```bash
# Get detailed output
dbt test --profiles-dir ../ --debug

# Test single model
dbt test --select stg_customers --profiles-dir ../

# Check compiled test SQL
cat target/compiled/clickhouse_analytics/models/staging/staging.yml/*.sql
```

**Airflow DAG fails:**
```bash
# Check scheduler logs
task logs-airflow

# Check task logs in UI
# http://localhost:8080 → DAG → Task → Logs

# Trigger with debug
docker compose exec airflow-webserver airflow tasks test clickhouse_analytics_pipeline check_clickhouse_connection 2024-01-01
```

**Data validation fails:**
```bash
# Check row counts
task validate-data

# Reload data
task reload-data

# Verify manually
task clickhouse-client
SELECT count(*) FROM staging.orders;
```

## Test Reporting

### Generate Test Report

```bash
# Run dbt with docs
task dbt-docs-generate

# Serve documentation
task dbt-docs-serve

# Open http://localhost:8080
# Navigate to "Tests" to see all test results
```

### Airflow Test Results

View in Airflow UI:
- DAG Runs: Shows success/failure of each run
- Task Instances: Detailed task-level results
- Logs: Full execution logs
- Gantt Chart: Performance visualization

## Best Practices

1. **Always test before deploying**
   - Run `task dbt-test` before committing
   - Verify in Airflow UI before production deploy

2. **Test at multiple levels**
   - Unit tests (individual models)
   - Integration tests (full pipeline)
   - Data quality tests (custom tests)

3. **Monitor continuously**
   - Set up Airflow alerts
   - Check logs regularly
   - Track query performance

4. **Document test failures**
   - Record expected vs actual results
   - Document resolution steps
   - Update tests as needed

5. **Automate testing**
   - Use pre-commit hooks
   - Set up CI/CD pipelines
   - Schedule regular test runs

## Test Checklist

Before considering pipeline production-ready:

- [ ] All Docker services start successfully
- [ ] ClickHouse accepts connections
- [ ] PostgreSQL accepts connections
- [ ] Airflow UI accessible
- [ ] All source data loaded
- [ ] All dbt models compile
- [ ] All dbt tests pass
- [ ] Airflow test DAG succeeds
- [ ] Analytics pipeline DAG succeeds
- [ ] Marts contain expected data
- [ ] Query performance acceptable
- [ ] Error handling works correctly
- [ ] Documentation complete
- [ ] No warnings in logs

## Summary

This testing framework ensures:
- Service reliability
- Data quality
- Model correctness
- Pipeline robustness
- Performance adequacy

Run tests regularly and before any changes to maintain pipeline health.
