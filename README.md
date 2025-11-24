# ClickHouse | dbt | Airflow Data Pipeline

Production-ready data pipeline using **ClickHouse** as the analytical database, **dbt** for data transformation, **Airflow** with **Astronomer Cosmos** for orchestration, and **Docker Compose** for local development.

## Features

- **ClickHouse OLAP Database**: High-performance columnar database optimized for analytical queries
- **dbt Transformations**: Modular SQL-based data modeling with staging, intermediate, and mart layers
- **Airflow Orchestration**: Automated pipeline scheduling and monitoring with Astronomer Cosmos integration
- **PostgreSQL Source**: Simulated OLTP source database with logical replication support
- **Docker Compose**: Complete local development environment with one command
- **Sample Data**: Pre-loaded datasets for immediate testing and exploration

## Quick Start

Get everything running in 60 seconds:

```bash
# 1. Install prerequisites
brew install docker go-task

# 2. Start the pipeline
task start

# 3. Access services
# ClickHouse: http://localhost:8123
# Airflow UI: http://localhost:8080 (admin/admin)
```

That's it! The pipeline is now running with:
- ClickHouse database with sample data
- Airflow UI for orchestration
- PostgreSQL source database
- dbt models ready to transform data

## Usage

### Run the Pipeline

**Option 1: Via Airflow (Recommended)**
1. Open http://localhost:8080 (admin/admin)
2. Enable the `clickhouse_analytics_pipeline` DAG
3. Trigger the DAG or wait for scheduled run

**Option 2: Via dbt CLI**
```bash
task dbt-build  # Run all models and tests
```

### Common Commands

```bash
# Service Management
task up           # Start all services
task down         # Stop all services
task status       # Check service health
task logs         # View all logs

# Database Operations
task clickhouse-client   # Interactive ClickHouse CLI
task postgres-client     # Interactive PostgreSQL CLI
task validate-data       # Check data in all tables

# dbt Operations
task dbt-run             # Run dbt models
task dbt-test            # Run dbt tests
task dbt-docs-serve      # View dbt documentation

# Airflow Operations
task airflow-list-dags      # List all DAGs
task airflow-analytics-dag  # Trigger analytics pipeline
```

### Query Data

```bash
task clickhouse-client

# Example queries:
SELECT count(*) FROM staging.orders;
SELECT * FROM marts.dim_customers LIMIT 10;
SELECT * FROM marts.daily_sales_summary;
```

## Architecture

```
CSV Files + PostgreSQL --> ClickHouse Staging --> dbt Transformations --> Analytics Marts
```

### Technology Stack

| Component | Technology | Port |
|-----------|------------|------|
| Database | ClickHouse | 8123 (HTTP), 9000 (Native) |
| Source DB | PostgreSQL | 5432 |
| Orchestration | Airflow | 8080 |
| Transformation | dbt | - |
| Integration | Astronomer Cosmos | - |

### Data Model

**Staging**: Clean source data (customers, products, orders, order_items)

**Marts**:
- `dim_customers`: Customer dimension with lifetime metrics
- `dim_products`: Product dimension with sales analytics
- `fct_orders`: Order fact table with profitability
- `daily_sales_summary`: Aggregated daily metrics

## Project Structure

```
clickhouse-db/
├── docker-compose.yml    # Service orchestration
├── Taskfile.yml          # Task runner configuration
├── data/                 # CSV seed data
├── clickhouse/           # ClickHouse config and init scripts
├── postgres/             # PostgreSQL init scripts
├── dbt/                  # dbt project
│   └── clickhouse_analytics/
└── airflow/              # Airflow DAGs and config
    └── dags/
```

## Documentation

- **[docs/QUICKSTART.md](docs/QUICKSTART.md)**: Getting started guide with setup commands
- **[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)**: System architecture and design decisions
- **[docs/REFERENCE.md](docs/REFERENCE.md)**: Testing, development workflow, and troubleshooting

## Development

### Adding New Models

1. Create SQL file in `dbt/clickhouse_analytics/models/`
2. Add tests in corresponding `.yml` file
3. Run `task dbt-run` to test
4. Airflow automatically picks up new models via Cosmos

### Connecting External Tools

**DBeaver/DataGrip:**
- Host: localhost
- Port: 8123 (HTTP) or 9000 (Native)
- Database: analytics
- User: default
- Password: clickhouse

## Troubleshooting

```bash
# Services won't start
docker info                    # Check Docker is running
task status                    # Check service status
task logs                      # View error logs

# No data in tables
task validate-data             # Check row counts
task reload-data               # Reload CSV data

# dbt connection errors
task dbt-debug                 # Test dbt connection
task clickhouse-test           # Verify ClickHouse
```

## Resources

- [ClickHouse Docs](https://clickhouse.com/docs)
- [dbt Documentation](https://docs.getdbt.com)
- [Airflow Documentation](https://airflow.apache.org/docs)
- [Astronomer Cosmos](https://astronomer.github.io/astronomer-cosmos/)
- [Task Documentation](https://taskfile.dev/)

## License

MIT License - See LICENSE file for details
