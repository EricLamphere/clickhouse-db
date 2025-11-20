# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a data pipeline project that integrates:
- **ClickHouse** as the primary database
- **dbt** for data transformation and ETL
- **Airflow** for orchestration and deployment
- **Docker Compose** for container orchestration

The goal is to create a self-contained data platform where `docker compose up` spins up both the ClickHouse database (with seed data) and the Airflow UI, which uses the `astronomer-cosmos` package to deploy dbt models and run tests.

## Project Structure

The repository uses a modular structure with separate directories for each component:
- `database/` - ClickHouse and Postgres database setup with initialization scripts
- `dbt/` - dbt project for data transformations
- `airflow/` - Airflow configuration and DAGs
- `dags/` - Airflow DAG definitions including dbt integration via Cosmos

Each component has its own Taskfile for component-specific operations, orchestrated by a root `Taskfile.yml`.

## Setup Commands

### Initial Setup
```bash
# Install dependencies first if not already installed:
# brew install dbt
# brew install go-task
# brew install docker-compose

# Run full setup (creates venvs and installs dependencies)
task setup
```

### Component-Specific Setup
The root Taskfile includes sub-taskfiles for each component:
```bash
task dbt:setup      # Setup dbt environment
task airflow:setup  # Setup Airflow environment
task database:setup # Setup database environment
```

### Reset Environment
```bash
task reset  # Removes all virtual environments
```

## Docker Compose Architecture

The main `compose.yml` orchestrates multiple services:

### ClickHouse Service
- Image: `clickhouse/clickhouse-server`
- Ports: 8123 (HTTP), 9000 (native protocol)
- Configuration files mounted from `database/fs/volumes/clickhouse/`
- Initialization scripts in `docker-entrypoint-initdb.d/`

### Postgres Service
- Used as a secondary data source for ClickHouse's `MaterializedPostgreSQL` engine
- Port: 5432
- Initialization scripts in `database/fs/volumes/postgres/docker-entrypoint-initdb.d/`
- Requires `wal_level=logical` for replication to ClickHouse

### Starting Services
```bash
docker compose up     # Start all services
docker compose down   # Stop all services
```

### Accessing ClickHouse
```bash
# Interactive client
docker compose exec clickhouse clickhouse-client

# Shell access
docker compose exec clickhouse bash
```

## dbt Configuration

The dbt project is configured for ClickHouse:
- Project name: `clickhouse`
- Profile: `clickhouse`
- Models default to `view` materialization (configurable per model)

### Running dbt
```bash
cd dbt
source venv/bin/activate
source utils/sh/setup.sh  # Environment setup script
dbt run
dbt test
```

## Airflow Configuration

Airflow uses the Astronomer Cosmos package to orchestrate dbt:
- Airflow version: 2.9.2
- Python version: 3.12
- DAGs are defined in `dags/` directory
- dbt integration via `cosmos.DbtDag`

### Example DAG Pattern
DAGs use Cosmos's `DbtDag` with:
- `ProjectConfig` pointing to dbt project path
- `ProfileConfig` with appropriate connection settings
- `ExecutionConfig` specifying dbt executable path

## Database Connection Details

### ClickHouse
- Host: localhost (127.0.0.1)
- HTTP Port: 8123
- Native Port: 9000

### Postgres
- Host: localhost
- Port: 5432
- User: admin
- Password: password
- Database: clickhouse_pg_db

## Development Notes

### Connecting to DBeaver
ClickHouse can be accessed via DBeaver using the ClickHouse JDBC driver on ports 8123 (HTTP) or 9000 (native).

### Multi-Source dbt Configuration
This project explores connecting dbt to multiple data sources (ClickHouse and Postgres), which requires careful profile and source configuration.

### MaterializedPostgreSQL Engine
ClickHouse uses the `MaterializedPostgreSQL` database engine to replicate data from Postgres. This requires:
- Postgres with `wal_level=logical`
- Proper permissions set in ClickHouse init scripts
- Replication configuration in ClickHouse

## Technology Stack

- **Database**: ClickHouse (columnar OLAP), PostgreSQL
- **Transformation**: dbt
- **Orchestration**: Apache Airflow with astronomer-cosmos
- **Container Management**: Docker Compose
- **Task Runner**: go-task (Taskfile)
- **Python Environment**: venv with component-specific requirements.txt files

## Resources

- [ClickHouse Quick Start](https://clickhouse.com/docs/en/getting-started/quick-start)
- [ClickHouse dbt docs](https://clickhouse.com/docs/en/integrations/dbt)
- [ClickHouse Compose Recipes](https://github.com/ClickHouse/examples/blob/main/docker-compose-recipes/README.md)
- [Taskfile docs](https://taskfile.dev/)
- [Airflow docs](https://airflow.apache.org/docs/apache-airflow/stable/start.html)
- [astronomer-cosmos](https://astronomer.github.io/astronomer-cosmos/getting_started/astro.html)
