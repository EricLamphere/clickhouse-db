# ClickHouse | dbt | Airflow Data Pipeline

Production-ready data pipeline using **ClickHouse** as the analytical database, **dbt** for data transformation, **Airflow** with **Astronomer Cosmos** for orchestration, and **Docker Compose** for local development.

## Features

- **ClickHouse OLAP Database**: High-performance columnar database optimized for analytical queries
- **dbt Transformations**: Modular SQL-based data modeling with staging, intermediate, and mart layers
- **Airflow Orchestration**: Automated pipeline scheduling and monitoring with Astronomer Cosmos integration
- **PostgreSQL Source**: Simulated OLTP source database with logical replication support
- **Docker Compose**: Complete local development environment with one command
- **Sample Data**: Pre-loaded datasets for immediate testing and exploration
- **Comprehensive Testing**: Built-in data quality tests and validation

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

## What You Get

### Data Architecture

```
CSV Files + PostgreSQL → ClickHouse Staging → dbt Transformations → Analytics Marts
```

### Pre-built Models

- **Staging**: Cleaned source data (customers, products, orders, order_items)
- **Intermediate**: Business logic and enrichment
- **Marts**:
  - `dim_customers`: Customer dimension with lifetime metrics
  - `dim_products`: Product dimension with sales analytics
  - `fct_orders`: Order fact table with profitability
  - `daily_sales_summary`: Aggregated daily metrics

### Sample Data

- 15 customers across 6 countries
- 15 products in 3 categories
- 20 orders with 32 line items
- PostgreSQL tables with user activities, inventory, and payment transactions

## Usage

### Run the Complete Pipeline

**Option 1: Via Airflow (Recommended)**
1. Open http://localhost:8080 (admin/admin)
2. Enable the `clickhouse_analytics_pipeline` DAG
3. Trigger the DAG or wait for scheduled run

**Option 2: Via dbt CLI**
```bash
task dbt-build  # Run all models and tests
```

### Common Operations

```bash
# Service Management
task up           # Start all services
task down         # Stop all services
task status       # Check service health
task logs         # View all logs

# Data Operations
task validate-data           # Check data in all tables
task clickhouse-test         # Test ClickHouse connection
task postgres-test           # Test PostgreSQL connection
task reload-data            # Reload CSV data

# dbt Operations
task dbt-run                # Run dbt models
task dbt-test               # Run dbt tests
task dbt-docs-serve         # View dbt documentation

# Airflow Operations
task airflow-list-dags      # List all DAGs
task airflow-analytics-dag  # Trigger analytics pipeline
```

### Query Data

**ClickHouse Client:**
```bash
task clickhouse-client

# Example queries:
SELECT count(*) FROM staging.orders;
SELECT * FROM marts.dim_customers LIMIT 10;
SELECT * FROM marts.daily_sales_summary;
```

**PostgreSQL Client:**
```bash
task postgres-client

# Example queries:
SELECT count(*) FROM source.user_activities;
SELECT * FROM source.inventory;
```

## Architecture

### Technology Stack

- **ClickHouse**: Analytical database (port 8123 HTTP, 9000 Native)
- **PostgreSQL**: Source database (port 5432)
- **Airflow**: Orchestration (port 8080)
- **dbt**: Data transformation
- **Astronomer Cosmos**: dbt-Airflow integration
- **Docker Compose**: Container orchestration

### Data Flow

1. **Initial Load**: CSV files → ClickHouse staging tables
2. **Replication**: PostgreSQL → ClickHouse (MaterializedPostgreSQL - future)
3. **Transformation**: dbt stages → intermediate → marts
4. **Orchestration**: Airflow schedules and monitors pipeline
5. **Analytics**: Query marts for insights

### dbt Model Layers

```
staging/          # Clean and standardize (views)
  ├── stg_customers.sql
  ├── stg_products.sql
  ├── stg_orders.sql
  └── stg_order_items.sql

intermediate/     # Business logic (views)
  ├── int_order_items_enriched.sql
  └── int_customer_orders.sql

marts/           # Analytics-ready (tables)
  ├── core/
  │   ├── dim_customers.sql
  │   ├── dim_products.sql
  │   └── fct_orders.sql
  └── metrics/
      └── daily_sales_summary.sql
```

## Project Structure

```
clickhouse-db/
├── docker-compose.yml           # Service orchestration
├── Taskfile.yml                # Common operations
├── data/                       # CSV seed data
├── clickhouse/                 # ClickHouse config & init
├── postgres/                   # PostgreSQL init
├── dbt/clickhouse_analytics/   # dbt project
│   ├── models/                # SQL transformations
│   └── tests/                 # Data quality tests
└── airflow/                    # Airflow DAGs & config
    └── dags/                  # Pipeline definitions
```

See [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) for complete details.

## Documentation

- **[SETUP.md](SETUP.md)**: Detailed setup and configuration guide
- **[ARCHITECTURE.md](ARCHITECTURE.md)**: System architecture and design decisions
- **[PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md)**: File organization and conventions

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

### Local dbt Development

```bash
cd dbt/clickhouse_analytics

# Test connection
dbt debug --profiles-dir ../

# Compile without running
dbt compile --profiles-dir ../

# Run specific model
dbt run --select stg_customers --profiles-dir ../

# Run models with tag
dbt run --select tag:staging --profiles-dir ../
```

## Monitoring

### Airflow UI (http://localhost:8080)
- DAG runs and task status
- Task logs and error messages
- Schedule management
- Manual triggering

### ClickHouse Metrics
```sql
-- Query performance
SELECT query, query_duration_ms
FROM system.query_log
ORDER BY event_time DESC
LIMIT 10;

-- Table sizes
SELECT
    database,
    table,
    formatReadableSize(sum(bytes)) as size
FROM system.parts
GROUP BY database, table
ORDER BY sum(bytes) DESC;
```

## Troubleshooting

### Services won't start
```bash
docker info                    # Check Docker is running
task status                   # Check service status
task logs                     # View error logs
```

### No data in tables
```bash
task validate-data            # Check row counts
task reload-data             # Reload CSV data
task clickhouse-test         # Verify ClickHouse
```

### Airflow DAGs not visible
```bash
task logs-airflow            # Check scheduler logs
task restart                 # Restart services
```

### dbt connection errors
```bash
task dbt-debug               # Test dbt connection
task clickhouse-test         # Verify ClickHouse is running
```

## Production Deployment

Before production:
1. Change all default passwords in `.env`
2. Enable ClickHouse authentication
3. Use CeleryExecutor or KubernetesExecutor for Airflow
4. Set up ClickHouse cluster with replication
5. Implement backup strategy for volumes
6. Configure monitoring and alerting
7. Review security settings

See [ARCHITECTURE.md](ARCHITECTURE.md) for production recommendations.

## Contributing

This project is a learning exercise and reference implementation. Feel free to:
- Fork and experiment
- Submit issues for bugs or questions
- Propose enhancements via pull requests

## Resources

### Documentation
- [ClickHouse Docs](https://clickhouse.com/docs)
- [dbt Documentation](https://docs.getdbt.com)
- [Airflow Documentation](https://airflow.apache.org/docs)
- [Astronomer Cosmos](https://astronomer.github.io/astronomer-cosmos/)
- [Task Documentation](https://taskfile.dev/)

### Related Examples
- [ClickHouse Compose Recipes](https://github.com/ClickHouse/examples/blob/main/docker-compose-recipes/README.md)
- [ClickHouse & Postgres Integration](https://github.com/ClickHouse/examples/tree/main/docker-compose-recipes/recipes/ch-and-postgres)
- [dbt Best Practices](https://docs.getdbt.com/guides/best-practices)

## License

MIT License - See LICENSE file for details

## Acknowledgments

Built using:
- ClickHouse by ClickHouse Inc.
- dbt by dbt Labs
- Apache Airflow by Apache Software Foundation
- Astronomer Cosmos by Astronomer

## Learning Goals

This project demonstrates:
- ClickHouse for high-performance analytics
- dbt for maintainable data transformations
- Airflow for production orchestration
- Docker Compose for reproducible environments
- Modern data engineering best practices

Perfect for learning or as a template for your own data pipelines!
