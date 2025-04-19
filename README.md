# Docker Compose Monitoring Stack

This project sets up a comprehensive monitoring stack using Docker Compose. It includes services for collecting, storing, and visualizing telemetry data (metrics, traces, and logs).

## Components

The stack consists of the following services:

*   **OpenTelemetry Collector (`otel`)**: Receives telemetry data via OTLP (gRPC on port 4317) and processes/exports it to the appropriate backends (Tempo, Loki, Prometheus).
*   **Prometheus (`prometheus`)**: A time-series database used for storing and querying metrics scraped from the OpenTelemetry Collector.
*   **Tempo (`tempo`)**: A high-scale, minimal-dependency distributed tracing backend. Stores traces received from the OpenTelemetry Collector.
*   **Loki (`loki`)**: A horizontally scalable, highly available, multi-tenant log aggregation system. Stores logs received from the OpenTelemetry Collector.
*   **Grafana (`grafana`)**: A multi-platform open source analytics and interactive visualization web application. Used to query and visualize data from Prometheus, Tempo, and Loki.

## Prerequisites

*   [Docker](https://docs.docker.com/get-docker/)
*   [Docker Compose](https://docs.docker.com/compose/install/)

## Setup

1.  **Clone the repository (or ensure you have the files):**
    ```bash
    # If applicable
    # git clone <your-repo-url>
    # cd <your-repo-directory>
    ```

2.  **Start the stack:**
    ```bash
    docker-compose up -d
    ```
    This command will build the necessary images (if not already present) and start all the services in detached mode.

## Accessing Services

*   **Grafana:** `http://localhost:3000`
    *   Default credentials: `admin` / `admin` (Configurable via `GF_SECURITY_ADMIN_PASSWORD` in `docker-compose.yml`)
    *   Datasources for Prometheus, Tempo, and Loki are pre-provisioned.
*   **Prometheus:** `http://localhost:9090` (Typically accessed via Grafana)
*   **Tempo:** Accessed via Grafana datasource (Internal port: `3200`)
*   **Loki:** Accessed via Grafana datasource (Internal port: `3100`)
*   **OpenTelemetry Collector:** Listens for OTLP gRPC data on `0.0.0.0:4317`.

## Configuration

Configuration files for each service are located within their respective directories:

*   **Otel Collector:** `./otel-collector/otel-collector-config.yaml`
*   **Prometheus:** `./prometheus/prometheus.yml`
*   **Tempo:** `./tempo/tempo.yaml`
*   **Loki:** `./loki/loki-config.yaml`
*   **Grafana Provisioning:** `./grafana/provisioning/` (Datasources, dashboards)

Modify these files as needed and restart the specific service or the entire stack:

```bash
# Restart a specific service (e.g., tempo)
docker-compose restart tempo

# Restart the entire stack
docker-compose down
docker-compose up -d
```

## Data Persistence

Data for Prometheus, Tempo, Loki, and Grafana is persisted using named Docker volumes:

*   `prometheus-data`
*   `tempo-data`
*   `loki-data`
*   `grafana-storage`

To remove the data, you can stop the stack and remove the volumes:

```bash
docker-compose down -v
```

## Sending Data

Applications need to be configured to send telemetry data (traces, metrics, logs) to the OpenTelemetry Collector endpoint: `otel-collector:4317` (within the Docker network) or `localhost:4317` (if running the application outside Docker on the same host). Use OTLP exporters (gRPC recommended).
