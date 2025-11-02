# FROM quay.io/astronomer/astro-runtime:13.1.0
FROM quay.io/astronomer/astro-runtime:12.9.0

# Install Docker provider
RUN pip install apache-airflow-providers-docker

RUN pip install apache-airflow-providers-slack