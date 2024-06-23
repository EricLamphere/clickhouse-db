# Clickhouse | dbt | Airflow
Database deployment and transformations using Clickhouse as the database, dbt for ETL, and Airflow for deployment


## Setup
If you don't have Taskfile installed, install it with
```sh
brew install go-task
```


## TODO
* **general**
  * github actions to deploy dbt docs and run tests
* **airflow**
  * Create `Dockerfile` and `compose.yml` file, enabling `docker compose up` to spin up airflow UI and run pipelines
* **dbt**
  * models
  * macros
  * thorough tests


## Resources
* [ClickHouse quick start](https://clickhouse.com/docs/en/getting-started/quick-start)
* [ClickHouse dbt docs](https://clickhouse.com/docs/en/integrations/dbt)
* [ClickHouse compose recipes](https://github.com/ClickHouse/examples/blob/main/docker-compose-recipes/README.md)
* [Taskfile docs](https://taskfile.dev/)
* [Airflow docs](https://airflow.apache.org/docs/apache-airflow/stable/start.html)
* [dbt docs](https://docs.getdbt.com/docs/introduction)