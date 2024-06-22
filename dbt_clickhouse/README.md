# Clickhouse dbt

## Setup
cd into the dbt directory
```sh
cd dbt_clickhouse
```

If you don't have Taskfile installed, install it with
```sh
brew install go-task
```

Run the following to set everything up. Alternatively, run `source init.sh`
```sh
task setup
source venv/bin/activate
source utils/sh/setup.sh
```