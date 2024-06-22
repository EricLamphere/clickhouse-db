# Clickhouse | dbt | Airflow
Database deployment and transformations using Clickhouse as the database, dbt for ETL, and Airflow for deployment


## Getting Started
If you don't have Taskfile installed, install it with
```sh
brew install go-task
```


## TODO
* **General**
  * Add an `init.sh` script to each folder
    * Should run `eval $(task start)` where `task start` just `echo`'s the commands that need to be executed in the your shell environment
* **database**
  * Create load script that loads data into clickhouse database
* **airflow**
  * Create `compose.yml` file, enabling `docker compose up` to spin up airflow UI and run pipelines
* **dbt**
  * models
  * macros
  * thorough tests


## Resources
* [Clickhouse dbt docs](https://clickhouse.com/docs/en/integrations/dbt)
* [Clickhouse quick start](https://clickhouse.com/docs/en/getting-started/quick-start)
* [Taskfile docs](https://taskfile.dev/)
* [Airflow docs](https://airflow.apache.org/docs/apache-airflow/stable/start.html)
* [dbt docs](https://docs.getdbt.com/docs/introduction)