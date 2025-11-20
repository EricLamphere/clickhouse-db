"""
ClickHouse Analytics Pipeline DAG

This DAG orchestrates the dbt models using Astronomer Cosmos.
It creates a task for each dbt model and handles dependencies automatically.
"""

from datetime import datetime, timedelta
from pathlib import Path

from airflow import DAG
from airflow.operators.python import PythonOperator
from cosmos import DbtTaskGroup, ProjectConfig, ProfileConfig, ExecutionConfig


# Default arguments for the DAG
default_args = {
    'owner': 'data_engineering',
    'depends_on_past': False,
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

# dbt project configuration
DBT_PROJECT_PATH = Path('/opt/airflow/dbt/clickhouse_analytics')
DBT_PROFILES_PATH = Path('/opt/airflow/dbt')


def check_clickhouse_connection():
    """
    Verify ClickHouse connection before running dbt models.
    """
    from clickhouse_driver import Client

    try:
        client = Client(
            host='clickhouse',
            port=9000,
            user='default',
            password='clickhouse',
            database='analytics'
        )

        # Test query
        result = client.execute('SELECT 1')
        print(f"ClickHouse connection successful: {result}")
        return True
    except Exception as e:
        print(f"ClickHouse connection failed: {e}")
        raise


def verify_source_data():
    """
    Verify that source data exists in the staging schema.
    """
    from clickhouse_driver import Client

    client = Client(
        host='clickhouse',
        port=9000,
        user='default',
        password='clickhouse',
        database='analytics'
    )

    tables = ['customers', 'products', 'orders', 'order_items']

    for table in tables:
        count = client.execute(f'SELECT count(*) FROM staging.{table}')[0][0]
        print(f"Table staging.{table} has {count} rows")

        if count == 0:
            raise ValueError(f"No data found in staging.{table}")

    print("All source tables have data")


# Profile configuration for ClickHouse
# Uses the profiles.yml file from the dbt directory
profile_config = ProfileConfig(
    profile_name='clickhouse_analytics',
    target_name='dev',
    profiles_yml_filepath=DBT_PROFILES_PATH / 'profiles.yml',
)

# Execution configuration
execution_config = ExecutionConfig(
    dbt_executable_path='/home/airflow/.local/bin/dbt',
)

# Create the DAG
with DAG(
    'clickhouse_analytics_pipeline',
    default_args=default_args,
    description='Analytics pipeline using dbt and ClickHouse',
    schedule_interval='@daily',
    start_date=datetime(2024, 1, 1),
    catchup=False,
    tags=['dbt', 'clickhouse', 'analytics'],
) as dag:

    # Pre-flight checks
    check_connection = PythonOperator(
        task_id='check_clickhouse_connection',
        python_callable=check_clickhouse_connection,
    )

    verify_data = PythonOperator(
        task_id='verify_source_data',
        python_callable=verify_source_data,
    )

    # dbt task group using Cosmos
    # This automatically creates tasks for each dbt model and handles dependencies
    dbt_tg = DbtTaskGroup(
        group_id='dbt_analytics',
        project_config=ProjectConfig(
            dbt_project_path=DBT_PROJECT_PATH,
        ),
        profile_config=profile_config,
        execution_config=execution_config,
        operator_args={
            'install_deps': True,  # Run dbt deps before running models
        },
        default_args={
            'retries': 2,
            'retry_delay': timedelta(minutes=3),
        },
    )

    # Set task dependencies
    check_connection >> verify_data >> dbt_tg
