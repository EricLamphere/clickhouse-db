# Project Structure

Complete directory structure and file organization for the ClickHouse data pipeline.

```
clickhouse-db/
├── README.md                          # Main project documentation
├── SETUP.md                           # Detailed setup instructions
├── ARCHITECTURE.md                    # System architecture documentation
├── PROJECT_STRUCTURE.md               # This file
├── CLAUDE.md                          # Claude-specific documentation
├── Taskfile.yml                       # Task runner configuration
├── docker-compose.yml                 # Docker Compose orchestration
├── requirements.txt                   # Python dependencies
├── .env.example                       # Environment variables template
├── .env                              # Environment variables (gitignored)
├── .gitignore                        # Git ignore rules
│
├── data/                             # Sample CSV data files
│   ├── customers.csv                 # Customer master data
│   ├── products.csv                  # Product catalog
│   ├── orders.csv                    # Order transactions
│   └── order_items.csv               # Order line items
│
├── clickhouse/                       # ClickHouse configuration and init
│   ├── config/
│   │   └── custom.xml                # ClickHouse server configuration
│   └── init/                         # Initialization SQL scripts
│       ├── 01_create_databases.sql   # Database creation
│       ├── 02_create_tables.sql      # Table definitions
│       └── 03_load_csv_data.sql      # CSV data loading
│
├── postgres/                         # PostgreSQL source database
│   └── init/                         # Initialization SQL scripts
│       ├── 01_create_tables.sql      # Source table creation
│       ├── 02_insert_data.sql        # Sample data insertion
│       └── 03_create_user.sql        # Replication user setup
│
├── dbt/                              # dbt project root
│   ├── profiles.yml                  # dbt connection profiles
│   └── clickhouse_analytics/         # dbt project
│       ├── dbt_project.yml           # Project configuration
│       ├── packages.yml              # dbt package dependencies
│       ├── requirements.txt          # Python dependencies
│       ├── .gitkeep                  # Preserve directory in git
│       │
│       ├── models/                   # dbt models
│       │   ├── sources.yml           # Source definitions
│       │   │
│       │   ├── staging/              # Staging models
│       │   │   ├── staging.yml       # Staging model documentation
│       │   │   ├── stg_customers.sql
│       │   │   ├── stg_products.sql
│       │   │   ├── stg_orders.sql
│       │   │   └── stg_order_items.sql
│       │   │
│       │   ├── intermediate/         # Intermediate models
│       │   │   ├── int_order_items_enriched.sql
│       │   │   └── int_customer_orders.sql
│       │   │
│       │   └── marts/                # Mart models
│       │       ├── marts.yml         # Mart documentation
│       │       ├── core/             # Core dimensional models
│       │       │   ├── dim_customers.sql
│       │       │   ├── dim_products.sql
│       │       │   └── fct_orders.sql
│       │       └── metrics/          # Aggregated metrics
│       │           └── daily_sales_summary.sql
│       │
│       ├── macros/                   # dbt macros (custom)
│       ├── tests/                    # Custom tests
│       ├── analyses/                 # Ad-hoc analyses
│       ├── snapshots/                # Snapshot models
│       ├── seeds/                    # Seed data
│       ├── docs/                     # Documentation
│       ├── target/                   # Compiled SQL (gitignored)
│       ├── dbt_packages/             # Installed packages (gitignored)
│       └── logs/                     # dbt logs (gitignored)
│
└── airflow/                          # Airflow orchestration
    ├── Dockerfile                    # Airflow container image
    ├── requirements.txt              # Python dependencies
    │
    ├── dags/                         # Airflow DAG definitions
    │   ├── clickhouse_analytics_dag.py   # Main analytics pipeline
    │   └── test_connections_dag.py       # Connection testing
    │
    ├── logs/                         # Airflow logs (gitignored)
    │   └── .gitkeep                  # Preserve directory
    │
    └── plugins/                      # Airflow plugins (gitignored)
        └── .gitkeep                  # Preserve directory
```

## Directory Descriptions

### Root Level

- **Documentation Files**: README, SETUP, ARCHITECTURE provide comprehensive project documentation
- **Taskfile.yml**: Task runner with common operations (start, stop, test, etc.)
- **docker-compose.yml**: Orchestrates all services (ClickHouse, Postgres, Airflow)
- **requirements.txt**: Python dependencies for local development
- **.env.example**: Template for environment variables

### `/data`

Contains CSV files used as initial data sources:
- Loaded into ClickHouse staging schema on initialization
- Read-only mount in containers
- Can be updated and reloaded with `task reload-data`

### `/clickhouse`

ClickHouse-specific configuration:

- **config/custom.xml**: Server configuration including:
  - Network settings
  - User authentication
  - Performance tuning
  - PostgreSQL connection pools

- **init/*.sql**: Initialization scripts run on first startup:
  - Create databases (analytics, staging)
  - Define staging tables with MergeTree engine
  - Load data from CSV files

### `/postgres`

PostgreSQL source database setup:

- **init/*.sql**: Scripts run on first startup:
  - Enable logical replication
  - Create source schema and tables
  - Insert sample data
  - Create replication user for ClickHouse

Tables simulate OLTP workload:
- user_activities
- inventory
- payment_transactions

### `/dbt`

dbt project for data transformation:

- **profiles.yml**: Connection configuration for ClickHouse
- **clickhouse_analytics/**: Main dbt project

#### dbt Project Structure

- **dbt_project.yml**: Project settings, model configurations, variables
- **packages.yml**: Dependencies (dbt_utils, etc.)
- **models/sources.yml**: Source definitions with tests

**Model Layers**:

1. **staging/**: Source data cleaning
   - One model per source table
   - Standardize column names
   - Basic transformations
   - Materialized as views

2. **intermediate/**: Business logic
   - Join multiple sources
   - Apply business rules
   - Calculate derived metrics
   - Materialized as views

3. **marts/**: Analytics-ready models
   - **core/**: Dimensional models (facts and dimensions)
   - **metrics/**: Aggregated metrics for reporting
   - Materialized as tables with partitioning

### `/airflow`

Airflow orchestration setup:

- **Dockerfile**: Custom Airflow image with:
  - astronomer-cosmos plugin
  - dbt-clickhouse adapter
  - Required Python packages

- **requirements.txt**: Python dependencies installed in container

- **dags/**: DAG definitions
  - **clickhouse_analytics_dag.py**: Main pipeline using Cosmos
  - **test_connections_dag.py**: Validation and testing

- **logs/**: Task execution logs (mounted volume)
- **plugins/**: Custom operators/hooks (mounted volume)

## File Naming Conventions

### dbt Models

- **Staging**: `stg_<source>_<table>.sql`
  - Example: `stg_customers.sql`

- **Intermediate**: `int_<description>.sql`
  - Example: `int_order_items_enriched.sql`

- **Marts**: `<type>_<entity>.sql`
  - Facts: `fct_<entity>.sql` (e.g., `fct_orders.sql`)
  - Dimensions: `dim_<entity>.sql` (e.g., `dim_customers.sql`)
  - Metrics: `<frequency>_<metric>.sql` (e.g., `daily_sales_summary.sql`)

### SQL Scripts

- Numbered for execution order: `01_`, `02_`, `03_`
- Descriptive names: `create_tables.sql`, `insert_data.sql`

### Configuration Files

- Service-specific: `<service>_config.yml`
- Environment: `.env`, `.env.example`
- Project: `dbt_project.yml`, `docker-compose.yml`

## Volume Mounts

Docker volumes for persistence and development:

1. **Persistent Data**:
   - `postgres_data`: PostgreSQL data
   - `clickhouse_data`: ClickHouse data
   - `airflow_postgres_data`: Airflow metadata

2. **Development Mounts**:
   - `./dbt:/opt/airflow/dbt`: Edit dbt models locally
   - `./airflow/dags:/opt/airflow/dags`: Edit DAGs locally
   - `./data:/data:ro`: CSV data files (read-only)
   - `./airflow/logs:/opt/airflow/logs`: Access logs

## Configuration Files

### docker-compose.yml

Defines services:
- postgres (source database)
- clickhouse (analytical database)
- airflow-postgres (Airflow metadata)
- airflow-init (one-time setup)
- airflow-webserver (UI)
- airflow-scheduler (orchestration)

### dbt_project.yml

Project configuration:
- Model paths and materialization
- Schema naming
- Test configuration
- Variables

### profiles.yml

Database connections:
- ClickHouse connection details
- Custom settings (timeouts, compression)

### Taskfile.yml

Common tasks:
- Service management (up, down, restart)
- Database operations (query, client)
- dbt operations (run, test, docs)
- Airflow operations (trigger, list)
- Data operations (reload, validate)

## Adding New Components

### New dbt Model

1. Create SQL file in appropriate layer
2. Add documentation in `models/<layer>/<layer>.yml`
3. Add tests
4. Run: `task dbt-run`

### New Data Source

1. Add initialization script in `clickhouse/init/` or `postgres/init/`
2. Update `models/sources.yml`
3. Create staging model
4. Restart: `task restart`

### New Airflow DAG

1. Create Python file in `airflow/dags/`
2. DAG appears automatically in UI
3. No restart needed (with auto-reload)

### New Macro or Test

1. Add to `dbt/clickhouse_analytics/macros/` or `tests/`
2. Reference in models
3. Run: `task dbt-compile`

## Git Management

### Tracked Files

- All source code and configuration
- Documentation
- Sample data (CSV files)
- .gitkeep files for empty directories

### Ignored Files

- Python virtual environments
- dbt compiled artifacts (target/, dbt_packages/)
- Airflow logs and runtime files
- Docker volumes and runtime data
- Environment files (.env)
- IDE configuration

See `.gitignore` for complete list.

## Best Practices

1. **Keep data small**: Sample data only, not production datasets
2. **Document changes**: Update .yml files when adding models
3. **Test thoroughly**: Add tests for all models
4. **Use task runner**: Prefer `task <command>` over manual Docker commands
5. **Version control**: Commit configuration, not data or artifacts
6. **Environment variables**: Never commit secrets or passwords
