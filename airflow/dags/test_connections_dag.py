"""
Test Connections DAG

Simple DAG to test connections to all data sources:
- ClickHouse
- PostgreSQL (source database)
- PostgreSQL (Airflow metadata database)
"""

from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator


default_args = {
    'owner': 'data_engineering',
    'depends_on_past': False,
    'email_on_failure': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=1),
}


def test_clickhouse_connection():
    """Test ClickHouse connection."""
    from clickhouse_driver import Client

    try:
        client = Client(
            host='clickhouse',
            port=9000,
            user='default',
            password='clickhouse'
        )

        # Get version
        version = client.execute('SELECT version()')[0][0]
        print(f"ClickHouse version: {version}")

        # List databases
        databases = client.execute('SHOW DATABASES')
        print(f"Databases: {databases}")

        # Test query
        result = client.execute('SELECT 1 as test')
        print(f"Test query result: {result}")

        return "ClickHouse connection successful!"

    except Exception as e:
        print(f"ClickHouse connection failed: {e}")
        raise


def test_postgres_source_connection():
    """Test PostgreSQL source database connection."""
    import psycopg2

    try:
        conn = psycopg2.connect(
            host='postgres',
            port=5432,
            database='source_db',
            user='postgres',
            password='postgres'
        )

        cursor = conn.cursor()

        # Get version
        cursor.execute('SELECT version()')
        version = cursor.fetchone()[0]
        print(f"PostgreSQL version: {version}")

        # List schemas
        cursor.execute("SELECT schema_name FROM information_schema.schemata")
        schemas = cursor.fetchall()
        print(f"Schemas: {schemas}")

        # Test query
        cursor.execute('SELECT 1 as test')
        result = cursor.fetchone()
        print(f"Test query result: {result}")

        cursor.close()
        conn.close()

        return "PostgreSQL source connection successful!"

    except Exception as e:
        print(f"PostgreSQL source connection failed: {e}")
        raise


def test_clickhouse_data():
    """Check data in ClickHouse staging tables."""
    from clickhouse_driver import Client

    client = Client(
        host='clickhouse',
        port=9000,
        user='default',
        password='clickhouse'
    )

    # Check staging tables
    tables = client.execute("SHOW TABLES FROM staging")
    print(f"Staging tables: {tables}")

    # Count rows in each table
    for (table,) in tables:
        count = client.execute(f'SELECT count(*) FROM staging.{table}')[0][0]
        print(f"Table staging.{table}: {count} rows")

    return "ClickHouse data check successful!"


def test_postgres_data():
    """Check data in PostgreSQL source tables."""
    import psycopg2

    conn = psycopg2.connect(
        host='postgres',
        port=5432,
        database='source_db',
        user='postgres',
        password='postgres'
    )

    cursor = conn.cursor()

    # List tables in source schema
    cursor.execute("""
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = 'source'
    """)
    tables = cursor.fetchall()
    print(f"Source tables: {tables}")

    # Count rows in each table
    for (table,) in tables:
        cursor.execute(f'SELECT count(*) FROM source.{table}')
        count = cursor.fetchone()[0]
        print(f"Table source.{table}: {count} rows")

    cursor.close()
    conn.close()

    return "PostgreSQL data check successful!"


with DAG(
    'test_connections',
    default_args=default_args,
    description='Test connections to all data sources',
    schedule_interval=None,  # Manual trigger only
    start_date=datetime(2024, 1, 1),
    catchup=False,
    tags=['testing', 'connections'],
) as dag:

    test_ch = PythonOperator(
        task_id='test_clickhouse_connection',
        python_callable=test_clickhouse_connection,
    )

    test_pg = PythonOperator(
        task_id='test_postgres_connection',
        python_callable=test_postgres_source_connection,
    )

    test_ch_data = PythonOperator(
        task_id='test_clickhouse_data',
        python_callable=test_clickhouse_data,
    )

    test_pg_data = PythonOperator(
        task_id='test_postgres_data',
        python_callable=test_postgres_data,
    )

    # Set dependencies
    test_ch >> test_ch_data
    test_pg >> test_pg_data
