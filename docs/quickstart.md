# Quick Start Guide

Get the ClickHouse data pipeline running in under 2 minutes.

## Prerequisites

```bash
# Install Docker Desktop and Task
brew install docker go-task

# Verify installations
docker --version
task --version
```

## One-Command Setup

```bash
# From project root
task quickstart
```

This command will:
1. Create `.env` configuration file
2. Start all Docker services (ClickHouse, PostgreSQL, Airflow)
3. Initialize databases and load sample data
4. Set up Airflow with admin user
5. Wait for all services to be healthy

Expected runtime: 60-90 seconds

## Access Points

After quickstart completes:

| Service | URL | Credentials |
|---------|-----|-------------|
| ClickHouse HTTP | http://localhost:8123 | default / clickhouse |
| ClickHouse Native | localhost:9000 | default / clickhouse |
| PostgreSQL | localhost:5432 | postgres / postgres |
| Airflow UI | http://localhost:8080 | admin / admin |

## Verify Everything Works

### 1. Check Service Status

```bash
task status
```

Expected output: All services showing "healthy" or "running"

### 2. Validate Data

```bash
task validate-data
```

Expected output:
```
ClickHouse staging data:
customers: 15 rows
products: 15 rows
orders: 20 rows
order_items: 32 rows

Postgres source data:
user_activities: 10 rows
inventory: 10 rows
payment_transactions: 10 rows
```

### 3. Test Connections

```bash
# ClickHouse
task clickhouse-test

# PostgreSQL
task postgres-test
```

## Run Your First Pipeline

### Option A: Via Airflow (Recommended)

1. Open Airflow UI: http://localhost:8080
2. Login: `admin` / `admin`
3. Find DAG: `clickhouse_analytics_pipeline`
4. Toggle to enable (switch on right side)
5. Click "Trigger DAG" (play button)
6. Watch tasks execute in Graph view

### Option B: Via dbt CLI

```bash
# Run all dbt models
task dbt-build
```

This will:
- Install dbt dependencies
- Run all staging models
- Run all intermediate models
- Run all mart models
- Execute all tests

Expected output: All models and tests passing

## Query the Results

### ClickHouse CLI

```bash
# Open ClickHouse client
task clickhouse-client

# Run queries:
SELECT count(*) FROM staging.customers;
SELECT * FROM marts.dim_customers LIMIT 5;
SELECT * FROM marts.daily_sales_summary;
```

### PostgreSQL CLI

```bash
# Open PostgreSQL client
task postgres-client

# Run queries:
SELECT count(*) FROM source.user_activities;
SELECT * FROM source.inventory LIMIT 5;
```

## Common First Steps

### 1. Explore dbt Models

```bash
# View model lineage and documentation
task dbt-docs-serve

# Opens browser at http://localhost:8080
# Shows DAG, model descriptions, column details
```

### 2. View Airflow Logs

```bash
# All Airflow logs
task logs-airflow

# Specific service
task logs-clickhouse
task logs-postgres
```

### 3. Modify a dbt Model

```bash
# Edit a model
nano dbt/clickhouse_analytics/models/marts/core/dim_customers.sql

# Test changes
task dbt-run

# Or trigger via Airflow
task airflow-analytics-dag
```

### 4. Connect with DBeaver

1. Open DBeaver
2. New Connection → ClickHouse
3. Settings:
   - Host: localhost
   - Port: 8123 (HTTP) or 9000 (Native)
   - Database: analytics
   - User: default
   - Password: clickhouse
4. Test Connection → Connect

## What to Explore

### dbt Models

```
dbt/clickhouse_analytics/models/
├── staging/              # Clean source data
├── intermediate/         # Business logic
└── marts/               # Analytics-ready tables
```

### Airflow DAGs

```
airflow/dags/
├── clickhouse_analytics_dag.py    # Main analytics pipeline
└── test_connections_dag.py        # Connection tests
```

### Sample Data

```
data/
├── customers.csv        # 15 customers
├── products.csv         # 15 products
├── orders.csv          # 20 orders
└── order_items.csv     # 32 line items
```

## Useful Commands

```bash
# Service Control
task up              # Start services
task down            # Stop services
task restart         # Restart all
task clean           # Remove everything (WARNING!)

# Database Queries
task clickhouse-query -- "SELECT count(*) FROM staging.orders"
task postgres-query -- "SELECT count(*) FROM source.inventory"

# dbt Operations
task dbt-run         # Run models
task dbt-test        # Run tests
task dbt-compile     # Check syntax

# Airflow Operations
task airflow-list-dags           # List all DAGs
task airflow-analytics-dag       # Trigger pipeline
task airflow-test-dag           # Test connections
```

## Next Steps

1. **Read the Documentation**:
   - [SETUP.md](SETUP.md) - Detailed setup guide
   - [ARCHITECTURE.md](ARCHITECTURE.md) - System design
   - [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) - File organization

2. **Modify the Pipeline**:
   - Add new dbt models
   - Create custom analyses
   - Add data quality tests

3. **Experiment**:
   - Query ClickHouse with different patterns
   - Test incremental models
   - Try MaterializedPostgreSQL (future)

4. **Learn More**:
   - ClickHouse query optimization
   - Advanced dbt techniques
   - Airflow scheduling patterns

## Troubleshooting

### Services Not Starting

```bash
# Check Docker
docker info

# View logs
task logs

# Rebuild images
task rebuild
```

### No Data in Tables

```bash
# Reload data
task reload-data

# Check status
task validate-data
```

### Airflow Not Accessible

```bash
# Wait for initialization (can take 60 seconds)
sleep 60

# Check logs
task logs-airflow

# Restart
task restart
```

### Port Conflicts

Edit `docker-compose.yml` to change ports if 8080, 8123, 5432, or 9000 are already in use.

## Getting Help

- Check logs: `task logs`
- Verify services: `task status`
- Restart: `task restart`
- Clean slate: `task clean` then `task up`

## Stop Everything

```bash
# Stop services (keep data)
task down

# Stop and remove all data
task clean
```

## Summary

You now have:
- ✅ ClickHouse OLAP database
- ✅ PostgreSQL source database
- ✅ Airflow orchestration
- ✅ dbt transformations
- ✅ Sample data loaded
- ✅ Working pipelines

Start exploring and building your own data models!
