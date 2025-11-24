# Reference

This document covers testing, validation, development workflows, and additional reference material.

## Testing & Validation

### Quick Validation

Run after setup to verify everything works:

```bash
task status           # Check all services are healthy
task validate-data    # Validate data loaded correctly
task clickhouse-test  # Test ClickHouse connection
task postgres-test    # Test PostgreSQL connection
task airflow-test-dag # Trigger test DAG in Airflow
```

### Data Validation

**ClickHouse Staging Data:**

```bash
task clickhouse-client
```

```sql
-- Check table row counts
SELECT 'customers' as table_name, count(*) as row_count FROM staging.customers
UNION ALL SELECT 'products', count(*) FROM staging.products
UNION ALL SELECT 'orders', count(*) FROM staging.orders
UNION ALL SELECT 'order_items', count(*) FROM staging.order_items;

-- Expected: customers=15, products=15, orders=20, order_items=32
```

**PostgreSQL Source Data:**

```bash
task postgres-client
```

```sql
-- Check table row counts
SELECT 'user_activities' as table_name, count(*) as row_count FROM source.user_activities
UNION ALL SELECT 'inventory', count(*) FROM source.inventory
UNION ALL SELECT 'payment_transactions', count(*) FROM source.payment_transactions;

-- Expected: 10 rows in each table
```

### dbt Testing

```bash
# Run all tests
task dbt-test

# Test specific model
cd dbt/clickhouse_analytics
dbt test --select stg_customers --profiles-dir ../

# Run specific test types
dbt test --select test_type:unique --profiles-dir ../
dbt test --select test_type:not_null --profiles-dir ../
dbt test --select test_type:relationships --profiles-dir ../
```

**Test Categories:**
- Schema tests (unique, not_null, accepted_values)
- Relationship tests (foreign keys)
- Custom data quality tests

### Model Validation

```bash
# Compile models (check for errors)
task dbt-compile

# Run models by layer
dbt run --select staging --profiles-dir ../
dbt run --select intermediate --profiles-dir ../
dbt run --select marts --profiles-dir ../

# Run specific model and all downstream
dbt run --select stg_customers+ --profiles-dir ../
```

### Airflow Pipeline Testing

```bash
# Trigger test connections DAG
task airflow-test-dag

# Trigger main analytics pipeline
task airflow-analytics-dag

# View logs
task logs-airflow
```

Monitor in Airflow UI at http://localhost:8080.

## Development Workflow

### Local Development

1. Edit dbt models in `dbt/clickhouse_analytics/models/`
2. Test locally: `task dbt-run`
3. Changes are automatically mounted in Airflow container
4. Trigger DAG in Airflow to test orchestration

### Adding New dbt Models

1. Create SQL file in appropriate directory:
   - `models/staging/` - Source data cleaning
   - `models/intermediate/` - Business logic
   - `models/marts/` - Final analytics models

2. Add documentation and tests in corresponding `.yml` file

3. Test: `task dbt-run`

4. Airflow automatically picks up new models via Cosmos

### Adding New Data Sources

**CSV Files:**
1. Add CSV to `data/` directory
2. Create table in `clickhouse/init/02_create_tables.sql`
3. Load data in `clickhouse/init/03_load_csv_data.sql`
4. Restart: `task restart`

**PostgreSQL Tables:**
1. Add table creation in `postgres/init/01_create_tables.sql`
2. Add data in `postgres/init/02_insert_data.sql`
3. Restart: `task restart`

### Adding New Airflow DAGs

1. Create Python file in `airflow/dags/`
2. DAG appears automatically in UI (no restart needed)

### dbt Model Naming Conventions

- **Staging**: `stg_<source>_<table>.sql` (e.g., `stg_customers.sql`)
- **Intermediate**: `int_<description>.sql` (e.g., `int_order_items_enriched.sql`)
- **Facts**: `fct_<entity>.sql` (e.g., `fct_orders.sql`)
- **Dimensions**: `dim_<entity>.sql` (e.g., `dim_customers.sql`)
- **Metrics**: `<frequency>_<metric>.sql` (e.g., `daily_sales_summary.sql`)

## Query Examples

### ClickHouse Queries

```sql
-- Query performance analysis
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

-- Mart queries
SELECT * FROM marts.dim_customers LIMIT 10;
SELECT * FROM marts.daily_sales_summary ORDER BY sales_date DESC;
```

### Python Integration

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

## Technologies & Versions

| Technology | Version | Purpose |
|------------|---------|---------|
| ClickHouse | latest | Analytical database (OLAP) |
| PostgreSQL | 15 | Source database (OLTP) |
| Apache Airflow | 2.8.1 | Orchestration |
| dbt-clickhouse | 1.7.2 | Data transformation |
| astronomer-cosmos | 1.3.0 | dbt-Airflow integration |
| Docker | latest | Containerization |

## Environment Variables

All configurable via `.env` file:
- Database credentials
- Service ports
- Airflow security keys
- dbt configuration

See `.env.example` for available options.

## Production Considerations

Before deploying to production:

1. **Change default passwords** in `.env`:
   - ClickHouse password
   - PostgreSQL passwords
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

## Troubleshooting

### Common Issues

**Services won't start:**
```bash
docker info              # Check Docker is running
task status              # Check service status
task logs                # View error logs
```

**ClickHouse connection errors:**
```bash
task clickhouse-test     # Test connection
docker compose ps clickhouse  # Check container health
task logs-clickhouse     # View ClickHouse logs
```

**Airflow DAGs not appearing:**
```bash
docker compose ps airflow-scheduler  # Check scheduler
task logs-airflow        # View scheduler logs
task restart             # Restart services
```

**dbt errors:**
```bash
task dbt-debug           # Debug connection
cat dbt/profiles.yml     # Check profiles
task clickhouse-test     # Verify ClickHouse
```

**Port conflicts:**
Stop conflicting services or modify ports in `docker-compose.yml`.

**Clean restart:**
```bash
task clean               # Remove everything (WARNING: destructive)
task start               # Start fresh
```

### Test Checklist

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

## Future Enhancements

Ready to implement:
1. MaterializedPostgreSQL real-time replication
2. Incremental dbt models for large datasets
3. Advanced metrics and KPIs
4. Machine learning integration
5. Real-time dashboards
6. Data quality framework (Great Expectations)
7. CI/CD pipeline (GitHub Actions)
8. Production deployment (Kubernetes)
