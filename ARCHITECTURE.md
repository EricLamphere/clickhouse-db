# Architecture Documentation

## Overview

This project implements a modern data pipeline using:
- **ClickHouse** as the analytical database
- **dbt** for data transformation
- **Airflow** with Astronomer Cosmos for orchestration
- **PostgreSQL** as a source database
- **Docker Compose** for local development and deployment

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Data Sources                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐              ┌──────────────┐                │
│  │ CSV Files    │              │ PostgreSQL   │                │
│  │ (Static Data)│              │ (OLTP Source)│                │
│  └──────┬───────┘              └──────┬───────┘                │
│         │                             │                        │
└─────────┼─────────────────────────────┼────────────────────────┘
          │                             │
          │                             │ (Future: Materialized
          │                             │  PostgreSQL Engine)
          │                             │
          ▼                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                        ClickHouse                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              Staging Schema                              │   │
│  │  • customers        • orders                            │   │
│  │  • products         • order_items                       │   │
│  │  (MergeTree tables, loaded from CSV)                    │   │
│  └─────────────────────────────────────────────────────────┘   │
│                           │                                     │
│                           │ dbt transformations                 │
│                           ▼                                     │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │           Analytics Schema (marts)                       │   │
│  │  • dim_customers    • fct_orders                        │   │
│  │  • dim_products     • daily_sales_summary               │   │
│  │  (Optimized MergeTree tables with partitioning)         │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                           ▲
                           │
                           │ SQL queries
                           │
┌─────────────────────────────────────────────────────────────────┐
│                      Orchestration Layer                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                  Apache Airflow                           │  │
│  │                                                           │  │
│  │  ┌────────────────┐      ┌────────────────┐             │  │
│  │  │  Webserver     │      │  Scheduler     │             │  │
│  │  │  (UI/API)      │      │  (Task Exec)   │             │  │
│  │  └────────────────┘      └────────────────┘             │  │
│  │                                                           │  │
│  │  ┌────────────────────────────────────────────────────┐  │  │
│  │  │        Astronomer Cosmos Plugin                    │  │  │
│  │  │  • Auto-generates Airflow tasks from dbt models   │  │  │
│  │  │  • Manages dependencies                           │  │  │
│  │  │  • Executes dbt commands                          │  │  │
│  │  └────────────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Component Details

### 1. ClickHouse Database

**Purpose**: High-performance analytical database optimized for OLAP workloads.

**Configuration**:
- Engine: MergeTree family
- Partitioning: By date (toYYYYMM) for time-series data
- Ordering: Optimized for common query patterns
- Compression: LZ4 for balance between speed and size

**Schemas**:
- `staging`: Raw data from sources
- `analytics`: Transformed data (intermediate + marts)
- `system`: ClickHouse internal tables

**Tables Design**:

1. **Staging Tables** (MergeTree):
   ```sql
   ENGINE = MergeTree()
   ORDER BY primary_key
   SETTINGS index_granularity = 8192
   ```

2. **Fact Tables** (Partitioned MergeTree):
   ```sql
   ENGINE = MergeTree()
   PARTITION BY toYYYYMM(date_field)
   ORDER BY (dimension_keys, date_field, id)
   ```

3. **Dimension Tables** (MergeTree):
   ```sql
   ENGINE = MergeTree()
   ORDER BY id
   ```

### 2. PostgreSQL Source Database

**Purpose**: Simulates OLTP source system with transactional data.

**Configuration**:
- Logical replication enabled (wal_level = logical)
- Publication created for ClickHouse replication
- Replication user with appropriate privileges

**Future Enhancement**:
ClickHouse MaterializedPostgreSQL engine will replicate data in real-time:
```sql
CREATE DATABASE postgres_replica
ENGINE = MaterializedPostgreSQL('postgres:5432', 'source_db', 'postgres', 'password');
```

### 3. dbt (Data Build Tool)

**Purpose**: Transform raw data into analytics-ready models using SQL.

**Project Structure**:
```
dbt/clickhouse_analytics/
├── models/
│   ├── staging/           # Clean source data
│   │   ├── stg_customers.sql
│   │   ├── stg_products.sql
│   │   ├── stg_orders.sql
│   │   └── stg_order_items.sql
│   ├── intermediate/      # Business logic
│   │   ├── int_order_items_enriched.sql
│   │   └── int_customer_orders.sql
│   └── marts/            # Analytics models
│       ├── core/
│       │   ├── dim_customers.sql
│       │   ├── dim_products.sql
│       │   └── fct_orders.sql
│       └── metrics/
│           └── daily_sales_summary.sql
├── dbt_project.yml       # Project configuration
└── packages.yml          # Dependencies
```

**Materialization Strategy**:
- Staging: `view` (fast, always fresh)
- Intermediate: `view` (no storage overhead)
- Marts: `table` (optimized for queries)

**Testing**:
- Schema tests (unique, not_null, accepted_values)
- Relationship tests (foreign keys)
- Custom data quality tests

### 4. Apache Airflow

**Purpose**: Orchestrate and schedule data pipeline execution.

**Components**:

1. **Webserver**:
   - UI for monitoring and manual triggers
   - Port 8080
   - Admin user: admin/admin

2. **Scheduler**:
   - Manages DAG execution
   - Task dependency resolution
   - Retry logic

3. **Executor**: LocalExecutor
   - Sufficient for local development
   - Production should use CeleryExecutor or KubernetesExecutor

4. **Metadata Database**: PostgreSQL
   - Stores DAG runs, task instances, logs
   - Separate from source database

### 5. Astronomer Cosmos

**Purpose**: Bridge between dbt and Airflow.

**Features**:
- Automatically converts dbt models to Airflow tasks
- Preserves dbt dependencies in Airflow DAG
- Handles dbt command execution
- Provides visibility into dbt runs

**DAG Structure**:
```python
DbtTaskGroup(
    group_id='dbt_analytics',
    project_config=ProjectConfig(...),
    profile_config=profile_config,
    execution_config=execution_config,
)
```

Cosmos creates one Airflow task per dbt model, maintaining dependencies.

## Data Flow

### Initial Load (CSV Data)

1. CSV files mounted in ClickHouse container at `/data`
2. Initialization scripts create staging tables
3. Data loaded using `file()` function:
   ```sql
   INSERT INTO staging.customers
   SELECT * FROM file('/data/customers.csv', 'CSVWithNames');
   ```

### PostgreSQL Replication (Future)

1. PostgreSQL logical replication enabled
2. Publication created for relevant tables
3. ClickHouse MaterializedPostgreSQL database created
4. Real-time replication of changes

### dbt Transformation Pipeline

1. **Staging Layer**:
   - Read from source tables
   - Standardize column names
   - Add derived fields
   - Type casting and validation

2. **Intermediate Layer**:
   - Join multiple sources
   - Apply business logic
   - Calculate derived metrics
   - Prepare for aggregation

3. **Marts Layer**:
   - Create dimension tables (SCD Type 1)
   - Build fact tables with metrics
   - Aggregate for reporting
   - Optimize for query performance

### Orchestration Flow

```
Start DAG
    │
    ├─> Check ClickHouse Connection
    │
    ├─> Verify Source Data
    │
    └─> dbt Task Group
        │
        ├─> dbt deps (install packages)
        │
        ├─> Staging Models (parallel)
        │   ├─> stg_customers
        │   ├─> stg_products
        │   ├─> stg_orders
        │   └─> stg_order_items
        │
        ├─> Intermediate Models
        │   ├─> int_order_items_enriched
        │   └─> int_customer_orders
        │
        └─> Mart Models (parallel)
            ├─> dim_customers
            ├─> dim_products
            ├─> fct_orders
            └─> daily_sales_summary
```

## Performance Considerations

### ClickHouse Optimization

1. **Partitioning Strategy**:
   - Partition by month for time-series data
   - Enables partition pruning
   - Facilitates data lifecycle management

2. **Ordering Keys**:
   - Order by common filter/join columns
   - Includes primary key and frequently filtered fields
   - Enables efficient range queries

3. **Granularity**:
   - Default 8192 rows per granule
   - Balanced for typical query patterns

4. **Compression**:
   - LZ4 for speed (default)
   - ZSTD for better compression if needed

### dbt Optimization

1. **Materialization**:
   - Views for lightweight transformations
   - Tables for complex aggregations
   - Incremental for large fact tables (future)

2. **Model Design**:
   - Minimize joins in final models
   - Pre-aggregate in intermediate models
   - Leverage ClickHouse functions (toStartOfMonth, etc.)

### Airflow Optimization

1. **Task Parallelism**:
   - Independent models run in parallel
   - Controlled by max_active_tasks

2. **Resource Management**:
   - Task-level resource requirements
   - Queue management for priorities

3. **Monitoring**:
   - Task duration tracking
   - SLA monitoring
   - Alert on failures

## Scalability

### Current Architecture (Development)

- Single ClickHouse node
- LocalExecutor for Airflow
- Docker Compose orchestration
- Suitable for: Development, testing, small datasets

### Production Architecture (Recommended)

1. **ClickHouse Cluster**:
   - Multiple shards for horizontal scaling
   - Replication for high availability
   - Distributed tables for query distribution

2. **Airflow**:
   - CeleryExecutor with worker pools
   - Redis for message broker
   - Separate scheduler and webserver

3. **Database**:
   - Managed PostgreSQL for Airflow metadata
   - Connection pooling
   - Regular backups

4. **Infrastructure**:
   - Kubernetes for container orchestration
   - Auto-scaling based on load
   - Load balancer for ClickHouse queries

## Security

### Current Implementation (Development)

- Basic authentication
- Default passwords
- Internal Docker network

### Production Recommendations

1. **Authentication**:
   - Strong passwords (rotate regularly)
   - Role-based access control
   - Service accounts for applications

2. **Encryption**:
   - TLS for ClickHouse connections
   - Encrypted volumes
   - Secrets management (HashiCorp Vault, AWS Secrets Manager)

3. **Network**:
   - Firewall rules
   - VPN or private networks
   - Rate limiting

4. **Audit**:
   - Query logging
   - Access logging
   - Alert on suspicious activity

## Monitoring and Observability

### Metrics to Track

1. **ClickHouse**:
   - Query execution time
   - Memory usage
   - Disk I/O
   - Query queue length
   - Merge operations

2. **Airflow**:
   - DAG run duration
   - Task success/failure rate
   - Scheduler lag
   - Worker utilization

3. **dbt**:
   - Model execution time
   - Test failures
   - Row counts
   - Freshness checks

### Logging

- Centralized logging (ELK stack, CloudWatch)
- Structured logs
- Log retention policies
- Error tracking (Sentry)

## Disaster Recovery

### Backup Strategy

1. **Data Backups**:
   - ClickHouse snapshots (daily)
   - PostgreSQL dumps (daily)
   - Volume backups (Docker volumes)

2. **Configuration Backups**:
   - Git repository (code and config)
   - Environment variables
   - Secrets (encrypted)

### Recovery Procedures

1. **Database Restore**:
   - Restore from snapshot
   - Replay replication logs
   - Verify data integrity

2. **Service Recovery**:
   - Redeploy from Docker images
   - Restore configurations
   - Validate connections

## Future Enhancements

1. **MaterializedPostgreSQL Integration**:
   - Real-time replication from PostgreSQL
   - Automated schema synchronization

2. **Incremental Models**:
   - Implement incremental materialization in dbt
   - Reduce processing time for large tables

3. **Advanced Analytics**:
   - Machine learning models
   - Real-time dashboards
   - Predictive analytics

4. **Data Quality**:
   - Great Expectations integration
   - Automated data profiling
   - Anomaly detection

5. **Multi-Source Integration**:
   - Additional source databases
   - API integrations
   - Streaming data sources
