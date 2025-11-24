# Quick Start

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
task start
```

This command will:
1. Create `.env` configuration file
2. Start all Docker services (ClickHouse, PostgreSQL, Airflow)
3. Initialize databases and load sample data
4. Set up Airflow with admin user
5. Wait for all services to be healthy

Expected runtime: 60-90 seconds

## Access Points

| Service | URL | Credentials |
|---------|-----|-------------|
| ClickHouse HTTP | http://localhost:8123 | default / clickhouse |
| ClickHouse Native | localhost:9000 | default / clickhouse |
| PostgreSQL | localhost:5432 | postgres / postgres |
| Airflow UI | http://localhost:8080 | admin / admin |

## Verify Everything Works

```bash
# Check service status
task status

# Validate data loaded correctly
task validate-data

# Test database connections
task clickhouse-test
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
# Run all dbt models and tests
task dbt-build
```

## Query the Results

### ClickHouse CLI

```bash
# Open ClickHouse client
task clickhouse-client

# Example queries:
SELECT count(*) FROM staging.customers;
SELECT * FROM marts.dim_customers LIMIT 5;
SELECT * FROM marts.daily_sales_summary;
```

### PostgreSQL CLI

```bash
# Open PostgreSQL client
task postgres-client

# Example queries:
SELECT count(*) FROM source.user_activities;
SELECT * FROM source.inventory LIMIT 5;
```

## Common Commands

### Service Management

```bash
task up           # Start all services
task down         # Stop all services (keep data)
task restart      # Restart all services
task status       # Check service health
task logs         # View all logs
task clean        # Stop and remove all data (WARNING!)
```

### Database Operations

```bash
task clickhouse-client           # Interactive ClickHouse CLI
task clickhouse-test             # Test ClickHouse connection
task clickhouse-query -- "SQL"   # Run ClickHouse query

task postgres-client             # Interactive PostgreSQL CLI
task postgres-test               # Test PostgreSQL connection
task postgres-query -- "SQL"     # Run PostgreSQL query
```

### dbt Operations

```bash
task dbt-run         # Run dbt models
task dbt-test        # Run dbt tests
task dbt-build       # Run models + tests
task dbt-compile     # Check syntax
task dbt-docs-serve  # View dbt documentation
```

### Airflow Operations

```bash
task airflow-list-dags      # List all DAGs
task airflow-analytics-dag  # Trigger analytics pipeline
task airflow-test-dag       # Test connections DAG
task logs-airflow           # View Airflow logs
```

### Data Operations

```bash
task validate-data   # Check row counts in all tables
task reload-data     # Reload CSV data into ClickHouse
```

## Connect External Tools

### DBeaver / DataGrip

**ClickHouse:**
- Host: localhost
- Port: 8123 (HTTP) or 9000 (Native)
- Database: analytics
- User: default
- Password: clickhouse

**PostgreSQL:**
- Host: localhost
- Port: 5432
- Database: source_db
- User: postgres
- Password: postgres

## Explore the Project

### dbt Models
```
dbt/clickhouse_analytics/models/
├── staging/          # Clean source data
├── intermediate/     # Business logic
└── marts/            # Analytics-ready tables
```

### Airflow DAGs
```
airflow/dags/
├── clickhouse_analytics_dag.py    # Main pipeline
└── test_connections_dag.py        # Connection tests
```

### Sample Data
```
data/
├── customers.csv    # 15 customers
├── products.csv     # 15 products
├── orders.csv       # 20 orders
└── order_items.csv  # 32 line items
```

## Troubleshooting

### Services Not Starting

```bash
docker info              # Check Docker is running
task logs                # View error logs
task restart             # Restart all services
```

### No Data in Tables

```bash
task validate-data       # Check row counts
task reload-data         # Reload CSV data
```

### Airflow Not Accessible

```bash
# Wait for initialization (can take 60 seconds)
sleep 60
task logs-airflow        # Check logs
task restart             # Restart services
```

### Port Conflicts

If ports 8080, 8123, 5432, or 9000 are already in use, edit `docker-compose.yml` to change the port mappings.

### dbt Connection Errors

```bash
task dbt-debug           # Test dbt connection
task clickhouse-test     # Verify ClickHouse is running
```

### Clean Restart

```bash
task clean               # Remove everything
task start               # Start fresh
```

## Stop Everything

```bash
# Stop services (keep data)
task down

# Stop and remove all data
task clean
```

## Next Steps

1. **Explore dbt documentation**: `task dbt-docs-serve`
2. **Monitor pipelines**: http://localhost:8080
3. **Query data**: `task clickhouse-client`
4. **Modify models**: Edit files in `dbt/clickhouse_analytics/models/`
5. **Read the docs**: See [ARCHITECTURE.md](ARCHITECTURE.md) and [REFERENCE.md](REFERENCE.md)
