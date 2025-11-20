# Setup Guide

Complete guide to setting up and running the ClickHouse data pipeline.

## Prerequisites

Install the following tools before starting:

1. **Docker Desktop** - [Install Docker](https://docs.docker.com/desktop/install/mac-install/)
2. **Docker Compose** - Included with Docker Desktop
3. **Task** (go-task) - `brew install go-task`
4. **dbt** (optional for local development) - `brew install dbt`

Verify installations:
```bash
docker --version
docker compose version
task --version
```

## Quick Start

The fastest way to get everything running:

```bash
# 1. Clone the repository (if you haven't already)
git clone <repository-url>
cd clickhouse-db

# 2. Run quickstart (sets up everything)
task quickstart
```

This will:
- Create environment configuration
- Start all Docker services
- Initialize databases
- Load seed data
- Set up Airflow

After about 60 seconds, you'll have:
- **ClickHouse**: http://localhost:8123
- **Airflow UI**: http://localhost:8080 (username: admin, password: admin)

## Manual Setup

If you prefer step-by-step setup:

### 1. Environment Configuration

```bash
# Copy environment template
cp .env.example .env

# Edit .env if needed (optional - defaults work fine)
nano .env
```

### 2. Start Services

```bash
# Start all services
task up

# Check status
task status

# View logs
task logs
```

Services will be available at:
- ClickHouse HTTP: http://localhost:8123
- ClickHouse Native: localhost:9000
- PostgreSQL: localhost:5432
- Airflow Web: http://localhost:8080

### 3. Verify Data

```bash
# Validate data was loaded correctly
task validate-data

# Test ClickHouse
task clickhouse-test

# Test Postgres
task postgres-test
```

## Running the Data Pipeline

### Option 1: Via Airflow (Recommended)

1. Open Airflow UI: http://localhost:8080
2. Login with `admin` / `admin`
3. Enable the `clickhouse_analytics_pipeline` DAG
4. Trigger the DAG manually or wait for scheduled run

### Option 2: Via dbt Locally

```bash
# Install dbt dependencies
task dbt-deps

# Run all models
task dbt-run

# Run tests
task dbt-test

# Or run everything (models + tests)
task dbt-build
```

## Architecture Overview

### Data Flow

1. **Source Data**:
   - CSV files in `/data` directory → ClickHouse staging schema
   - Postgres tables → MaterializedPostgreSQL (future)

2. **dbt Transformation Layers**:
   - **Staging**: Clean and standardize source data
   - **Intermediate**: Business logic and enrichment
   - **Marts**: Analytics-ready dimensional models

3. **Orchestration**:
   - Airflow manages scheduling
   - Cosmos plugin integrates dbt with Airflow
   - DAGs handle dependencies and error recovery

### Services

- **ClickHouse**: OLAP database for analytics
- **PostgreSQL (source_db)**: OLTP source data
- **PostgreSQL (airflow)**: Airflow metadata database
- **Airflow Webserver**: UI and API
- **Airflow Scheduler**: Task orchestration

## Common Tasks

### Database Operations

```bash
# Connect to ClickHouse client
task clickhouse-client

# Run a ClickHouse query
task clickhouse-query -- "SELECT count(*) FROM staging.orders"

# Connect to Postgres client
task postgres-client

# Run a Postgres query
task postgres-query -- "SELECT count(*) FROM source.user_activities"
```

### dbt Operations

```bash
# Compile models (check for errors)
task dbt-compile

# Run specific model
cd dbt/clickhouse_analytics
dbt run --select stg_customers --profiles-dir ../

# Run models with specific tag
dbt run --select tag:staging --profiles-dir ../

# Generate documentation
task dbt-docs-generate
task dbt-docs-serve
```

### Airflow Operations

```bash
# List all DAGs
task airflow-list-dags

# Trigger test connections DAG
task airflow-test-dag

# Trigger analytics pipeline
task airflow-analytics-dag

# View Airflow logs
task logs-airflow
```

### Data Management

```bash
# Reload CSV data
task reload-data

# Validate all data
task validate-data
```

## Troubleshooting

### Services won't start

```bash
# Check Docker is running
docker info

# View service status
task status

# Check logs for errors
task logs
```

### ClickHouse connection errors

```bash
# Test connection
task clickhouse-test

# Check ClickHouse is healthy
docker compose ps clickhouse

# View ClickHouse logs
task logs-clickhouse
```

### Airflow DAGs not appearing

```bash
# Check Airflow scheduler is running
docker compose ps airflow-scheduler

# View scheduler logs
task logs-airflow

# Restart Airflow services
task restart
```

### dbt errors

```bash
# Debug connection
task dbt-debug

# Check profiles configuration
cat dbt/profiles.yml

# Verify ClickHouse connection
task clickhouse-test
```

### Port conflicts

If ports 8080, 8123, 5432, or 9000 are already in use:

1. Stop conflicting services
2. Or modify ports in `docker-compose.yml`

### Clean restart

```bash
# Stop and remove all data (WARNING: destructive!)
task clean

# Start fresh
task up
```

## Development Workflow

### Local Development

1. Edit dbt models in `dbt/clickhouse_analytics/models/`
2. Test locally: `task dbt-run`
3. Changes are automatically mounted in Airflow container
4. Trigger DAG in Airflow to test in orchestration

### Adding New Models

1. Create SQL file in appropriate directory:
   - `models/staging/` - source data cleaning
   - `models/intermediate/` - business logic
   - `models/marts/` - final analytics models

2. Update `models/.../model_name.yml` with tests and documentation

3. Test: `task dbt-run`

4. Airflow will automatically pick up new models via Cosmos

### Adding New Data Sources

#### CSV Files:

1. Add CSV to `data/` directory
2. Create table in `clickhouse/init/02_create_tables.sql`
3. Load data in `clickhouse/init/03_load_csv_data.sql`
4. Restart: `task restart`

#### Postgres Tables:

1. Add table creation in `postgres/init/01_create_tables.sql`
2. Add data in `postgres/init/02_insert_data.sql`
3. Restart: `task restart`

## Connecting External Tools

### DBeaver (or other database clients)

**ClickHouse Connection:**
- Host: localhost
- Port: 8123 (HTTP) or 9000 (Native)
- Database: analytics
- User: default
- Password: clickhouse

**PostgreSQL Connection:**
- Host: localhost
- Port: 5432
- Database: source_db
- User: postgres
- Password: postgres

### Python Scripts

```python
from clickhouse_driver import Client

client = Client(
    host='localhost',
    port=9000,
    user='default',
    password='clickhouse',
    database='analytics'
)

result = client.execute('SELECT * FROM marts.dim_customers LIMIT 10')
```

## Production Considerations

Before deploying to production:

1. **Change default passwords** in `.env`:
   - ClickHouse password
   - Postgres passwords
   - Airflow admin password
   - Fernet key and secret key

2. **Update resource limits** in `docker-compose.yml`

3. **Configure backups** for volumes:
   - `postgres_data`
   - `clickhouse_data`
   - `airflow_postgres_data`

4. **Enable authentication** in ClickHouse configuration

5. **Set up monitoring** and alerting

6. **Use production Airflow executor** (CeleryExecutor or KubernetesExecutor)

7. **Review security settings** in all services

## Next Steps

- Explore dbt models in `dbt/clickhouse_analytics/models/`
- Review DAGs in `airflow/dags/`
- Check out dbt documentation: `task dbt-docs-serve`
- Monitor Airflow UI: http://localhost:8080
- Query ClickHouse: `task clickhouse-client`

## Resources

- [ClickHouse Documentation](https://clickhouse.com/docs)
- [dbt Documentation](https://docs.getdbt.com)
- [Airflow Documentation](https://airflow.apache.org/docs)
- [Cosmos Documentation](https://astronomer.github.io/astronomer-cosmos/)
- [Task Documentation](https://taskfile.dev/)
