# Use official Airflow image
FROM apache/airflow:2.8.1-python3.11

# Switch to root to install system dependencies
USER root

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements file as root first
COPY --chown=airflow:root requirements.txt /requirements.txt

# Switch back to airflow user
USER airflow

# Install Python dependencies
RUN pip install --no-cache-dir --user -r /requirements.txt

# Set environment variables
ENV PYTHONPATH="${PYTHONPATH}:/opt/airflow"
ENV AIRFLOW_HOME=/opt/airflow

# Create necessary directories
RUN mkdir -p /opt/airflow/dags /opt/airflow/logs /opt/airflow/plugins
