# Stock Market ETL Pipeline

A production-ready ETL pipeline that fetches, processes, and stores stock market data using Apache Airflow, Apache Spark, MinIO, and PostgreSQL.

## 📋 Overview

This project implements an end-to-end ETL pipeline for stock market data (NVDA - NVIDIA Corporation) that:
- Fetches real-time stock prices from a financial API
- Stores raw data in MinIO object storage
- Processes data using Apache Spark
- Loads formatted data into PostgreSQL data warehouse
- Visualizes data with Metabase

## 🏗️ Architecture

```
┌─────────────────┐
│  Stock API      │
│  (Yahoo Finance)│
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Airflow DAG    │
│  - API Sensor   │
│  - Fetch Prices │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  MinIO          │
│  (Object Store) │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Spark          │
│  (Transform)    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  PostgreSQL     │
│  (Data Warehouse)│
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Metabase       │
│  (Visualization)│
└─────────────────┘
```

## 🚀 Features

- **Automated Daily Execution**: Scheduled to run daily at midnight
- **API Health Check**: Sensor ensures API availability before processing
- **Distributed Processing**: Utilizes Apache Spark for scalable data transformation
- **Object Storage**: Stores raw and processed data in MinIO (S3-compatible)
- **Data Warehouse**: PostgreSQL for analytical queries
- **Containerized**: Fully Docker-based deployment
- **Visualization Ready**: Integrated with Metabase for dashboards

## 🛠️ Tech Stack

- **Orchestration**: Apache Airflow 2.x
- **Processing**: Apache Spark 3.5.0
- **Storage**: MinIO (S3-compatible object storage)
- **Database**: PostgreSQL
- **Visualization**: Metabase
- **Container**: Docker & Docker Compose

## 📦 Prerequisites

- Docker Engine 20.x+
- Docker Compose 2.x+
- Astronomer CLI (Astro CLI)
- 4GB+ RAM available
- 10GB+ disk space

### Install Astro CLI

**macOS/Linux:**
```bash
brew install astro
```

**Windows:**
```bash
winget install -e --id Astronomer.Astro
```

For other installation methods, visit: https://docs.astronomer.io/astro/cli/install-cli

## 🚀 Quick Start Guide

```bash
# 1. Clone the repository
git clone https://github.com/yourusername/stock-market-etl.git
cd stock-market-etl

# 2. Build Spark Docker image
cd spark/notebooks/stock_transform
docker build -t airflow/stock-app .

# 3. Return to project root
cd ../../..

# 4. Start Astronomer Airflow
astro dev start

# 5. Access Airflow UI
# Open browser: http://localhost:8080
# Login: admin / admin

# 6. Configure connections (see Configuration section below)

# 7. Enable and trigger the stock_market DAG
```

## 🔧 Setup Instructions

### 1. Clone Repository

```bash
git clone https://github.com/yourusername/stock-market-etl.git
cd stock-market-etl
```

### 2. Build Spark Docker Image

Navigate to the Spark notebook directory and build the custom image:

```bash
cd spark/notebooks/stock_transform
docker build -t airflow/stock-app .
```

### 3. Return to Project Root

```bash
cd ../../..
```

### 4. Start Astronomer Airflow Environment

```bash
astro dev start
```

This command will:
- Build and start all Docker containers
- Initialize Airflow database
- Create default admin user
- Start webserver, scheduler, and triggerer

**First-time startup may take 5-10 minutes.**

### 4. Configure Airflow Connections

Access Airflow UI at `http://localhost:8080`

**Default Credentials:** admin/admin

Navigate to **Admin → Connections** and add the following three connections:

#### Connection 1: MinIO (Object Storage)

Click **+** button to add new connection:

```
Connection Id: minio
Connection Type: Amazon Web Services
AWS Access Key ID: minio
AWS Secret Access Key: minio123
Extra: {
  "endpoint_url": "http://minio:9000"
}
```

**Note:** Leave all other fields empty

#### Connection 2: PostgreSQL (Data Warehouse)

Click **+** button to add new connection:

```
Connection Id: postgres
Connection Type: Postgres
Host: postgres
Schema: postgres
Login: postgres
Password: postgres
Port: 5432
```

**Note:** Adjust Schema, Login, and Password based on your PostgreSQL setup

#### Connection 3: Stock API (Yahoo Finance)

Click **+** button to add new connection:

```
Connection Id: stock_api
Connection Type: HTTP
Host: https://query1.finance.yahoo.com/
Extra: {
  "endpoint": "/v8/finance/chart/",
  "headers": {
    "Content-Type": "application/json",
    "User-Agent": "Mozilla/5.0",
    "Accept": "application/json"
  }
}
```

**Note:** Ensure the Host ends with a trailing slash (/)

#### Verify Connections

After adding all connections, you can test them:

1. Click on each connection
2. Click the **Test** button
3. Verify you see "Connection successfully tested"

![Airflow Connections](https://via.placeholder.com/800x400?text=Add+screenshot+of+Airflow+Connections+page)

### 5. Verify Installation

```bash
# Check running containers
docker ps

# Expected services:
# - airflow-webserver
# - airflow-scheduler
# - airflow-triggerer
# - postgres
# - minio
# - spark-master
# - spark-worker
# - metabase
```

### 6. Stop the Environment (when needed)

```bash
astro dev stop
```

### 7. Restart the Environment

```bash
astro dev restart
```


## 📊 Pipeline Details

### DAG: `stock_market`

**Schedule**: Daily (`@daily`)  
**Start Date**: January 1, 2023  
**Catchup**: Disabled

### Tasks

1. **is_api_available** (Sensor)
   - Checks if the Yahoo Finance API is accessible
   - Poke interval: 30 seconds
   - Timeout: 300 seconds (5 minutes)

2. **get_stock_prices** (PythonOperator)
   - Fetches NVDA stock prices from API
   - Returns JSON with OHLCV data

3. **store_prices** (PythonOperator)
   - Stores raw JSON data in MinIO
   - Path: `s3://stock-market/NVDA/YYYY-MM-DD.json`

4. **format_prices** (DockerOperator)
   - Runs Spark job to transform data
   - Converts JSON to formatted CSV
   - Executed in Docker container

5. **get_formatted_csv** (PythonOperator)
   - Retrieves formatted CSV path from MinIO

6. **load_to_dw** (Astro SQL)
   - Loads CSV data into PostgreSQL
   - Table: `public.stock_market`

## 🌐 Service URLs

| Service | URL | Credentials |
|---------|-----|-------------|
| Airflow | http://localhost:8080 | admin/admin |
| MinIO Console | http://localhost:9001 | minio/minio123 |
| Spark Master | http://localhost:8082 | - |
| Spark Worker | http://localhost:8081 | - |
| Metabase | http://localhost:3000 | Setup required |
| PostgreSQL | localhost:5433 | airflow/airflow |

## 📁 Project Structure

```
stock-market-etl/
├── dags/
│   └── stock_market.py          # Main DAG definition
├── include/
│   └── stock_market/
│       └── tasks.py             # Python callables
├── spark/
│   ├── master/
│   │   └── Dockerfile
│   ├── worker/
│   │   └── Dockerfile
│   └── notebooks/
│       └── stock_transform/
│           ├── Dockerfile       # Spark app Docker image
│           └── stock_transform.py
├── docker-compose.yaml
├── Dockerfile                   # Astronomer Airflow image
├── requirements.txt             # Python dependencies
├── packages.txt                 # System packages
└── README.md
```

## 🔍 Monitoring

### Airflow UI
- View DAG runs and task logs
- Monitor task duration and success rates
- Check XCom values between tasks

### Spark UI
- Monitor job execution
- View stage details and task metrics
- Track resource utilization

### MinIO Console
- Browse stored objects
- Monitor storage usage
- Manage buckets

### Reset Everything
```bash
# Stop and remove all containers
astro dev kill

# Remove volumes (WARNING: deletes all data)
docker volume prune

# Restart fresh
astro dev start
```

### Add Notifications (Optional)
Uncomment and configure Slack notifications:
```python
from airflow.providers.slack.notifications.slack_notifier import SlackNotifier

# Add to DAG parameters
default_args={
    'on_failure_callback': SlackNotifier(...)
}
```


## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.
