# Architecture

This document covers the system architecture, component connections, and Docker setup for the ClickHouse data pipeline.

## Overview

The pipeline integrates:
- **ClickHouse** - Analytical database (OLAP)
- **PostgreSQL** - Source database (OLTP)
- **dbt** - Data transformation
- **Airflow** with Astronomer Cosmos - Orchestration
- **Docker Compose** - Container orchestration

## System Diagram

```
                        Data Sources
    +------------------+              +------------------+
    | CSV Files        |              | PostgreSQL       |
    | (Static Data)    |              | (OLTP Source)    |
    +--------+---------+              +--------+---------+
             |                                 |
             |                                 | (Future: Materialized
             |                                 |  PostgreSQL Engine)
             v                                 v
    +----------------------------------------------------------+
    |                       ClickHouse                          |
    |  +----------------------------------------------------+  |
    |  |              Staging Schema                        |  |
    |  |  customers | products | orders | order_items       |  |
    |  |  (MergeTree tables, loaded from CSV)               |  |
    |  +----------------------------------------------------+  |
    |                           |                              |
    |                           | dbt transformations          |
    |                           v                              |
    |  +----------------------------------------------------+  |
    |  |           Analytics Schema (marts)                 |  |
    |  |  dim_customers | dim_products | fct_orders         |  |
    |  |  daily_sales_summary                               |  |
    |  |  (Optimized MergeTree tables with partitioning)    |  |
    |  +----------------------------------------------------+  |
    +----------------------------------------------------------+
                           ^
                           |
                           | SQL queries
                           |
    +----------------------------------------------------------+
    |                  Orchestration Layer                      |
    |  +----------------------------------------------------+  |
    |  |                 Apache Airflow                     |  |
    |  |  Webserver (UI/API)    |    Scheduler (Task Exec)  |  |
    |  |                                                    |  |
    |  |  +----------------------------------------------+  |  |
    |  |  |        Astronomer Cosmos Plugin              |  |  |
    |  |  |  - Auto-generates tasks from dbt models      |  |  |
    |  |  |  - Manages dependencies                      |  |  |
    |  |  |  - Executes dbt commands                     |  |  |
    |  |  +----------------------------------------------+  |  |
    |  +----------------------------------------------------+  |
    +----------------------------------------------------------+
```

## Data Flow

1. **Initial Load**: CSV files loaded into ClickHouse staging tables on container startup
2. **Replication**: PostgreSQL to ClickHouse (MaterializedPostgreSQL - future enhancement)
3. **Transformation**: dbt executes staging -> intermediate -> marts pipeline
4. **Orchestration**: Airflow schedules and monitors all pipeline runs
5. **Analytics**: Query mart tables for insights

## Component Details

### ClickHouse

High-performance columnar database optimized for OLAP workloads.

**Configuration:**
- Engine: MergeTree family
- Partitioning: By date (toYYYYMM) for time-series data
- Compression: LZ4 (default)

**Schemas:**
- `staging` - Raw data from sources
- `analytics` - Transformed data (intermediate + marts)

**Table Design Patterns:**

```sql
-- Staging Tables
ENGINE = MergeTree()
ORDER BY primary_key
SETTINGS index_granularity = 8192

-- Fact Tables (Partitioned)
ENGINE = MergeTree()
PARTITION BY toYYYYMM(date_field)
ORDER BY (dimension_keys, date_field, id)

-- Dimension Tables
ENGINE = MergeTree()
ORDER BY id
```

### PostgreSQL

Simulates OLTP source system with transactional data.

**Configuration:**
- Logical replication enabled (wal_level = logical)
- Publication created for ClickHouse replication
- Replication user with appropriate privileges

**Future Enhancement:** ClickHouse MaterializedPostgreSQL engine for real-time replication:
```sql
CREATE DATABASE postgres_replica
ENGINE = MaterializedPostgreSQL('postgres:5432', 'source_db', 'postgres', 'password');
```

### dbt

Transforms raw data into analytics-ready models using SQL.

**Model Layers:**
- **Staging**: Clean and standardize source data (views)
- **Intermediate**: Business logic and joins (views)
- **Marts**: Analytics-ready dimensional models (tables)

**Materialization Strategy:**
- Staging/Intermediate: `view` (no storage overhead, always fresh)
- Marts: `table` (optimized for query performance)

### Airflow

Orchestrates and schedules data pipeline execution.

**Components:**
- **Webserver**: UI and API (port 8080)
- **Scheduler**: Task orchestration and dependency resolution
- **Executor**: LocalExecutor (development), CeleryExecutor recommended for production
- **Metadata DB**: Separate PostgreSQL instance

### Astronomer Cosmos

Bridges dbt and Airflow by automatically converting dbt models to Airflow tasks while preserving dependencies.

## Docker Services

| Service | Image | Ports | Purpose |
|---------|-------|-------|---------|
| clickhouse | clickhouse/clickhouse-server | 8123 (HTTP), 9000 (Native) | Analytical database |
| postgres | postgres:15 | 5432 | Source database |
| airflow-postgres | postgres:15 | - | Airflow metadata |
| airflow-webserver | Custom Airflow | 8080 | Airflow UI |
| airflow-scheduler | Custom Airflow | - | Task scheduling |

**Service Dependencies:**
```
airflow-postgres -> airflow-init -> airflow-webserver
                                 -> airflow-scheduler
postgres -> clickhouse -> airflow containers
```

## Volume Mounts

**Persistent Volumes:**
- `postgres_data` - PostgreSQL source data
- `clickhouse_data` - ClickHouse analytics data
- `airflow_postgres_data` - Airflow metadata

**Development Mounts:**
- `./dbt:/opt/airflow/dbt` - Edit dbt models locally
- `./airflow/dags:/opt/airflow/dags` - Edit DAGs locally
- `./data:/data:ro` - CSV data files (read-only)
- `./airflow/logs:/opt/airflow/logs` - Access logs

## Project Structure

```
clickhouse-db/
├── docker-compose.yml      # Service orchestration
├── Taskfile.yml            # Task runner configuration
├── data/                   # CSV seed data
├── clickhouse/             # ClickHouse config and init scripts
├── postgres/               # PostgreSQL init scripts
├── dbt/                    # dbt project
│   └── clickhouse_analytics/
│       └── models/         # SQL transformations
└── airflow/                # Airflow configuration
    └── dags/               # Pipeline definitions
```

## Performance Considerations

### ClickHouse Optimization
- Partition by month for time-series data (enables partition pruning)
- Order by common filter/join columns
- Default 8192 rows per granule
- LZ4 compression for speed, ZSTD for better compression

### dbt Optimization
- Views for lightweight transformations
- Tables for complex aggregations
- Minimize joins in final models
- Pre-aggregate in intermediate models

### Airflow Optimization
- Independent models run in parallel
- Task-level resource requirements
- Queue management for priorities

## Scalability

### Current Architecture (Development)
- Single ClickHouse node
- LocalExecutor for Airflow
- Docker Compose orchestration
- Suitable for development, testing, small datasets

### Production Architecture (Recommended)
- **ClickHouse Cluster**: Multiple shards with replication
- **Airflow**: CeleryExecutor with worker pools, Redis broker
- **Database**: Managed PostgreSQL for Airflow metadata
- **Infrastructure**: Kubernetes with auto-scaling

## Security

### Development (Current)
- Basic authentication with default passwords
- Internal Docker network
- No TLS/SSL

### Production (Recommended)
- Strong, rotated passwords
- TLS for all connections
- Network segmentation and firewall rules
- Secrets management (HashiCorp Vault, AWS Secrets Manager)
- Query and access logging

## Monitoring

### Key Metrics

**ClickHouse:**
- Query execution time
- Memory usage
- Disk I/O
- Query queue length

**Airflow:**
- DAG run duration
- Task success/failure rate
- Scheduler lag

**dbt:**
- Model execution time
- Test failures
- Row counts

### Logging
- Centralized logging recommended (ELK stack, CloudWatch)
- Structured logs with retention policies
- Error tracking (Sentry)

## Disaster Recovery

### Backup Strategy
- ClickHouse snapshots (daily)
- PostgreSQL dumps (daily)
- Docker volume backups
- Git repository for code and config

### Recovery Procedures
1. Restore from snapshot/dump
2. Redeploy containers from images
3. Restore configurations
4. Validate data integrity and connections
