FROM quay.io/astronomer/astro-runtime:11.5.0

RUN python -m venv dbt_venv && \
    source dbt_venv/bin/activate && \
    pip install dbt-clickhouse --no-cache-dir && \
    deactivate