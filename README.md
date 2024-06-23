# Clickhouse | dbt | Airflow
Database deployment and transformations using **ClickHouse** as the database, **dbt** for ETL, and **Airflow** for deployment


## Goals

#### Learn ClickHouse & Airflow
This is mostly just me messing around and trying to learn how things work. My expertise level out of 10 before this project:
* ClickHouse: noob, 0
* Airflow: noob, 0
* dbt: experienced, ~8
* docker: experienced, ~6-7
* docker-compose: noobish, ~2
* GitHub Actions: meh, ~3
  * Lots of experience with GitLab CI/CD though

#### Create a Data Pipeline
Aside from learning new things, my main goal for the repo itself is to create a data pipeline using
* ClickHouse as the database
* dbt for ETL
* Airflow for deployment
* docker-compose for container orchestration

At the end of the day I'd like to have a parent `compose.yml` file that spins up a server for the ClickHouse database and Airflow UI. The ClickHouse database will have it's own initialization scripts that writes some seed data for the rest of the pipeline to handle. Airflow will use the `astronomer-cosmos` package to deploy dbt models and run tests.

#### Experiment
I'd also like to experiment with the following things:
* Connecting local ClickHouse server to DBeaver (my preferred free database tool)
* Test connecting dbt to multiple data sources - this is one thing I haven't done before


## Setup
Things you'll need to install if you haven't already
* dbt - `brew install dbt`
* go-task - `brew install go-task`
* Docker - [mac install](https://docs.docker.com/desktop/install/mac-install/)
* docker-compose - `brew install docker-compose`

Everything else should get installed for you using `task setup`


## TODO
* **general**
  * [x] Set up repo structure
    * [x] taskfiles
    * [x] requirements files
    * [x] venv
    * [x] readme
    * [x] init.sh
  * [ ] github actions to spin up ClickHouse and Airflow servers
  * [ ] parent `compose.yml` file that orchestrates everything
* **database**
  * [x] Set up `compose.yml` for spinning up ClickHouse server
  * [ ] Change database and schema names
  * [ ] Initialize different data?
* **airflow**
  * Create `Dockerfile` and `compose.yml` file, enabling `docker compose up` to spin up airflow UI and run pipelines
* **dbt**
  * models
  * macros
  * tests


## Resources
* [ClickHouse quick start](https://clickhouse.com/docs/en/getting-started/quick-start)
* [ClickHouse dbt docs](https://clickhouse.com/docs/en/integrations/dbt)
* [ClickHouse compose recipes](https://github.com/ClickHouse/examples/blob/main/docker-compose-recipes/README.md)
  * [ClickHouse & Postgres](https://github.com/ClickHouse/examples/tree/main/docker-compose-recipes/recipes/ch-and-postgres)
* [Taskfile docs](https://taskfile.dev/)
* [Airflow docs](https://airflow.apache.org/docs/apache-airflow/stable/start.html)
* [dbt docs](https://docs.getdbt.com/docs/introduction)