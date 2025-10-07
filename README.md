# Go Sample Metric with OpenTelemetry and Datadog Integration

This project demonstrates how to send metrics from a Go application using OpenTelemetry. It supports three deployment modes:
1. **Docker Compose (Recommended)**: Complete containerized setup with one command
2. **Direct to Datadog**: Send metrics directly to Datadog using OTLP exporters (production)
3. **Local Stack**: Go app → OTEL Collector → Prometheus → Grafana (development)

## Features

- **🐳 Complete Docker Setup**: One-command deployment with `docker compose up`
- **📊 Full Observability Stack**: Go app → OTEL Collector → Prometheus → Grafana
- **🚀 Direct Datadog Integration**: Send metrics directly to Datadog using OTLP exporters
- **📈 Pre-configured Dashboard**: Ready-to-use Grafana dashboard with key metrics
- **⚙️ Automated Provisioning**: Datasources and dashboards are automatically configured
- **📉 Comprehensive Metrics**: HTTP requests, latency, errors, and runtime metrics
- **🔧 Easy Setup**: Multiple deployment options for different environments
- **🧪 Load Testing**: Built-in scripts for generating test traffic
- **🔄 Flexible Exporters**: Support for both HTTP and gRPC OTLP exporters
- **🏥 Health Checks**: Built-in health monitoring for all services

## Architecture

**Docker Compose (Recommended)**:
```
Go App (Docker) → OTEL Collector (Docker) → Prometheus (Docker) → Grafana (Docker)
```

**Production (Datadog Direct)**:
```
Go App → Datadog OTLP Endpoint → Datadog Platform
```

**Development (Local Stack)**:
```
Go App → OTEL Collector → Prometheus → Grafana
```

## Quick Start

### 🚀 Option 1: Docker Compose (Recommended)

The fastest way to get everything running:

```bash
# Clone and navigate to the project
git clone <repository-url>
cd go-sample-metric

# Start all services (Go app + monitoring stack)
docker compose up --build

# Or use the convenient startup script
./start-docker.sh
```

**That's it!** All services will be running with:
- **Go Application**: http://localhost:8080
  - Health: http://localhost:8080/healthz
  - Work endpoint: http://localhost:8080/work
- **Grafana Dashboard**: http://localhost:3000 (admin/admin)
- **Prometheus**: http://localhost:9090

Generate some traffic:
```bash
# In another terminal
./test-load.sh
```

### 🔧 Option 2: Local Development

For development with hot-reload:

```bash
# Start monitoring services only
docker compose up prometheus otel-collector grafana -d

# Run Go app locally
go run main.go

# Generate traffic
./test-load.sh
```

### ☁️ Option 3: Datadog Direct (Production)

### ☁️ Option 3: Datadog Direct (Production)

Skip the local stack and send directly to Datadog:

```bash
# 1. Get your Datadog API key from Datadog → Organization Settings → API Keys

# 2. Configure for Datadog
cp .env.datadog .env
# Edit .env and set: DD_API_KEY=your_actual_datadog_api_key_here

# 3. Run the application (no Docker services needed!)
go run main.go

# 4. Generate traffic
./test-load.sh

# 5. View metrics in Datadog → Metrics → Summary
```

## 📋 Prerequisites

- **Go 1.23 or later** (for local development)
- **Docker and Docker Compose** (for containerized setup)
- **Git** (for cloning the repository)

## 🛠️ Building and Running

### Docker Setup (Recommended)

The project includes complete Docker support with:
- Multi-stage Docker build for optimized images
- Health checks for all services
- Environment-based configuration
- Automated service dependencies

**Build only the Go application:**
```bash
docker compose build go-sample-metric
```

**Start specific services:**
```bash
# Start monitoring stack only
docker compose up prometheus otel-collector grafana -d

# Start everything
docker compose up --build

# Run in background
docker compose up --build -d
```

**View service status:**
```bash
docker compose ps
```

**View logs:**
```bash
# All services
docker compose logs

# Specific service
docker compose logs go-sample-metric

# Follow logs
docker compose logs -f go-sample-metric
```

**Stop services:**
```bash
docker compose down

# Stop and remove volumes
docker compose down -v
```

### Local Development Build

```bash
# Build the application
go build -o sample-metric .

# Or run directly without building
go run main.go
```

## 🧪 Testing the Integration

Before deploying to production, validate your setup:

```bash
# Quick validation test (recommended)
./test-datadog-quick.sh

## 🐳 Docker Guide

For detailed Docker setup, configuration, and troubleshooting, see the **[DOCKER_GUIDE.md](DOCKER_GUIDE.md)**.

### Quick Docker Commands

```bash
# Start everything
docker compose up --build

# Start in background
docker compose up --build -d

# View status and health
docker compose ps

# View logs
docker compose logs go-sample-metric

# Stop everything
docker compose down

# Complete cleanup
docker compose down -v --rmi all
```

### Docker Configuration

The Docker setup uses `.env.docker` for configuration:

```bash
# View current Docker configuration
cat .env.docker

# Customize Docker settings
cp .env.docker .env.docker.local
# Edit .env.docker.local with your settings
```

### Docker Startup Scripts

The project includes convenient startup scripts:

```bash
# Complete Docker setup with cleanup handling
./start-docker.sh

# Traditional monitoring stack only
./start-demo.sh
```

**`start-docker.sh` features:**
- ✅ Builds and starts all services including Go app
- ✅ Handles cleanup on exit (Ctrl+C)
- ✅ Shows clear status messages
- ✅ Works with both `docker compose` and `docker-compose`

### Service URLs (Docker)

When running with Docker Compose:
- **Go Application**: http://localhost:8080
- **Grafana**: http://localhost:3000 (admin/admin)
- **Prometheus**: http://localhost:9090
- **OTEL Collector**: http://localhost:4318 (HTTP), localhost:4317 (gRPC)

### 1. Start the monitoring stack

Use the provided script to start all services:

```bash
./start-demo.sh
```

Or manually start with Docker Compose:

```bash
docker-compose up -d
```

This will start:
- **OTEL Collector** on ports 4317 (gRPC) and 4318 (HTTP)
- **Prometheus** on port 9090 (with automatic OTEL Collector scraping)
- **Grafana** on port 3000 (with pre-configured dashboard and datasource)

Wait for all services to be ready (about 10-15 seconds).

### 2. Run the Go application

In a new terminal, start the Go application:

```bash
go run main.go
```

You should see output like:
```
2025/09/30 11:54:15 starting service name=sample-metric-service env=development app=demo ver=0.1.0 port=8090 metrics_endpoint=http://localhost:4318/v1/metrics export_int=5s export_timeout=10s work_latency_ms=[50,300] error_rate=10%
2025/09/30 11:54:15 sample metric service listening on :8090 (exporting to http://localhost:4318/v1/metrics)
```

The application will:
- Start an HTTP server on port 8090
- Automatically send metrics to the OTEL Collector every 5 seconds
- Expose endpoints `/healthz` and `/work`

### 3. Generate traffic and metrics

#### Quick test:
```bash
# Health check
curl http://localhost:8090/healthz

# Single work request
curl http://localhost:8090/work
```

#### Generate continuous load:
```bash
# Use the provided load testing script
./test-load.sh
```

Or manually generate load:
```bash
# Generate work metrics (with simulated latency and errors)
for i in {1..50}; do
  curl -s http://localhost:8090/work
  echo "Request $i completed"
  sleep 0.5
done
```

### 4. Check metrics flow

#### Verify OTEL Collector is receiving metrics:
```bash
# Check collector logs (should show detailed metric data)
docker-compose logs otel-collector --tail=50
```

You should see detailed metric output like:
```
Metric #0
Descriptor:
     -> Name: http.server.request.count
     -> Description: Total number of received HTTP requests
     -> DataType: Sum
...
```

#### Verify Prometheus has metrics:
```bash
# List all available metrics
curl -s http://localhost:9090/api/v1/label/__name__/values

# Query specific metric
curl -s "http://localhost:9090/api/v1/query?query=sample_app_http_server_request_count_total"
```

### 5. View and analyze metrics

#### Option A: Pre-configured Grafana Dashboard (Recommended)
The project includes a pre-configured dashboard that automatically loads when you start Grafana:

1. Open http://localhost:3000
2. Login with **admin/admin**
3. Navigate to **Dashboards** → **Browse**
4. Open **"Go Sample Metrics - OpenTelemetry Dashboard"**

The dashboard includes the following panels:
- **Request Rate** - HTTP requests per second by route and status
- **Error Rate** - Percentage of failed requests over time
- **Response Time Percentiles** - 50th, 95th, and 99th percentile latency
- **Active Requests** - Current number of requests being processed
- **Runtime Goroutines** - Number of Go goroutines
- **Memory Allocation** - Heap memory usage in MB
- **Key Metrics Summary** - Important KPIs at a glance

#### Option B: Prometheus Query Interface
1. Open http://localhost:9090
2. Go to **Graph** tab
3. Try these queries:
   - `sample_app_http_server_request_count_total` - Total requests
   - `rate(sample_app_http_server_request_count_total[5m])` - Requests per second
   - `sample_app_http_server_request_duration_ms_milliseconds_bucket` - Latency distribution
   - `sample_app_process_runtime_goroutines` - Number of goroutines
   - `sample_app_http_server_active_requests` - Active requests

#### Option C: Custom Grafana Dashboard
1. Open http://localhost:3000
2. Login with **admin/admin**
3. The Prometheus data source is automatically configured at `http://prometheus:9090`
4. Create a new dashboard and add panels with queries like:
   - Request rate: `rate(sample_app_http_server_request_count_total[5m])`
   - Error rate: `rate(sample_app_http_server_request_count_total{error="true"}[5m])`
   - Average latency: `rate(sample_app_http_server_request_duration_ms_milliseconds_sum[5m]) / rate(sample_app_http_server_request_duration_ms_milliseconds_count[5m])`

## Configuration

### Environment Variables

The application can be configured via `.env` file or environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `SERVICE_NAME` | `sample-metric-service` | Service name for metrics identification |
| `SERVICE_ENV` | `development` | Environment name (dev, staging, prod) |
| `SERVICE_APP` | `demo` | Application name |
| `SERVICE_VERSION` | `0.1.0` | Service version |
| `PORT` | `8090` | HTTP server port |
| `METRIC_EXPORT_INTERVAL` | `5s` | How often to export metrics |
| `METRIC_EXPORT_TIMEOUT` | `10s` | Timeout for metric export |
| `WORK_MIN_LATENCY_MS` | `50` | Minimum simulated work latency |
| `WORK_MAX_LATENCY_MS` | `300` | Maximum simulated work latency |
| `ERROR_RATE_PERCENT` | `10` | Percentage of `/work` requests that return 500 errors |
| `SHUTDOWN_TIMEOUT` | `5s` | Graceful shutdown timeout |
| **Datadog Configuration** | | |
| `DD_ENABLED` | `false` | Set to `true` to enable direct Datadog export |
| `DD_API_KEY` | - | Your Datadog API key (**required** when `DD_ENABLED=true`) |
| `DD_SITE` | `datadoghq.com` | Datadog site based on your account region |
| `EXPORTER_TYPE` | `http` | Use `http` or `grpc` for OTLP export |
| **Custom OTLP Endpoint** | | |
| `OTEL_EXPORTER_OTLP_METRICS_ENDPOINT` | `http://localhost:9529/v1/metrics` | Custom OTLP endpoint (when `DD_ENABLED=false`) |

### Configuration Files

The project includes several configuration examples and setup files:

| File | Purpose | Usage |
|------|---------|-------|
| **Environment Configuration** | | |
| `.env` | Local development config | `cp .env.example .env` |
| `.env.docker` | Docker Compose config | Used automatically in Docker |
| `.env.datadog` | Datadog integration config | `cp .env.datadog .env` |
| **Docker Configuration** | | |
| `Dockerfile` | Multi-stage Go app build | Used by `docker compose build` |
| `docker-compose.yml` | Service orchestration | Defines all services and networking |
| `.dockerignore` | Docker build optimization | Excludes unnecessary files from build |
| **Scripts** | | |
| `start-docker.sh` | Complete Docker startup | `./start-docker.sh` |
| `start-demo.sh` | Traditional monitoring stack | `./start-demo.sh` |
| **Testing** | | |
| `test-datadog.sh` | Comprehensive integration test | Validates all Datadog configurations |
| `test-datadog-quick.sh` | Quick validation test | Fast check of basic functionality |
| `test-load.sh` | Traffic generation script | Creates test requests for metrics |
| **Monitoring Configuration** | | |
| `otel-collector.yaml` | OTEL Collector configuration | Defines metric pipelines |
| `prometheus.yml` | Prometheus scrape configuration | Defines metric collection |
| `grafana/provisioning/` | Grafana auto-configuration | Dashboards and datasources |

### Environment Configuration Examples

**For Docker development**:
```bash
# Uses .env.docker automatically
docker compose up --build
```

**For local development**:
```bash
cp .env.example .env
# Edit .env as needed
go run main.go
```

**For Datadog integration**:
```bash
cp .env.datadog .env
# Edit .env and set your DD_API_KEY
go run main.go
```

**For custom Docker config**:
```bash
cp .env.docker .env.docker.local
# Edit .env.docker.local with your settings
# Modify docker-compose.yml to use .env.docker.local
```

### Modifying Configuration

Edit the `.env` file to change settings:
```bash
# Example: Change error rate and latency
echo "ERROR_RATE_PERCENT=20" >> .env
echo "WORK_MAX_LATENCY_MS=500" >> .env

# Restart the Go application to apply changes
```

### Grafana Dashboard Configuration

The project includes automated Grafana provisioning:

**Dashboard Location**: `grafana/provisioning/dashboards/go-sample-metrics.json`
**Datasource Config**: `grafana/provisioning/datasources/prometheus.yml`

To customize the dashboard:
1. Modify `go-sample-metrics.json` directly, or
2. Make changes in Grafana UI and export the dashboard JSON
3. Restart Grafana to reload: `docker-compose restart grafana`

The dashboard automatically includes:
- Real-time metrics with 5-second refresh
- Proper Prometheus queries for all metrics
- Color-coded panels with thresholds
- Responsive layout optimized for monitoring

## Datadog Integration

This application now supports direct metric export to Datadog using OpenTelemetry OTLP exporters, bypassing the need for a local collector.

### Quick Setup for Datadog

1. **Get your Datadog API Key**: 
   - Login to Datadog → Organization Settings → API Keys
   - Create a new API key or copy an existing one

2. **Configure for Datadog**:
   ```bash
   # Copy the Datadog configuration template
   cp .env.datadog .env
   
   # Edit .env and replace your_actual_datadog_api_key_here with your real API key
   vim .env
   ```

3. **Run the application**:
   ```bash
   go run main.go
   ```

4. **Generate some traffic**:
   ```bash
   ./test-load.sh
   ```

5. **View metrics in Datadog**:
   - Go to Datadog → Metrics → Summary
   - Search for metrics starting with your service name (e.g., `sample_metric_service`)

### Datadog Configuration Options

| Variable | Default | Description |
|----------|---------|-------------|
| `DD_ENABLED` | `false` | Set to `true` to enable direct Datadog export |
| `DD_API_KEY` | - | Your Datadog API key (**required** when `DD_ENABLED=true`) |
| `DD_SITE` | `datadoghq.com` | Datadog site based on your account region |
| `EXPORTER_TYPE` | `http` | Use `http` or `grpc` for OTLP export |

### Supported Datadog Sites

Choose the correct `DD_SITE` based on your Datadog account region:
- `datadoghq.com` - US1 (default)
- `datadoghq.eu` - EU
- `us3.datadoghq.com` - US3  
- `us5.datadoghq.com` - US5
- `ap1.datadoghq.com` - AP1

### Architecture Comparison

**Local Development (Default)**:
```
Go App → OTEL Collector → Prometheus → Grafana
```

**Datadog Direct Export**:
```
Go App → Datadog OTLP Endpoint → Datadog Platform
```

### Metrics in Datadog

Once configured, your metrics will appear in Datadog with the following naming pattern:
- `otel.http.server.request.count` - HTTP request count
- `otel.http.server.request.duration.ms` - Request latency histogram  
- `otel.http.server.active_requests` - Active requests gauge
- `otel.process.runtime.goroutines` - Number of goroutines
- `otel.process.runtime.mem.alloc.bytes` - Memory allocation

All metrics include service tags like `service.name`, `service.version`, `service.env`, etc.

### Troubleshooting Datadog Integration

**Metrics not appearing in Datadog**:
1. Verify `DD_API_KEY` is correct and has metrics write permissions
2. Check `DD_SITE` matches your Datadog account region  
3. Ensure `DD_ENABLED=true` in your `.env` file
4. Check application logs for authentication errors

**Connection issues**:
1. Verify network connectivity to Datadog endpoints
2. Check firewall rules for HTTPS traffic
3. Try switching between `http` and `grpc` exporter types

## Available Metrics

The application generates the following metrics that you can query in Prometheus:

### HTTP Request Metrics
- **`sample_app_http_server_request_count_total`** - Total number of HTTP requests
  - Labels: `http_route`, `http_status_code`, `error`
  - Example query: `rate(sample_app_http_server_request_count_total[5m])`

- **`sample_app_http_server_request_duration_ms_*`** - Request latency histogram
  - Includes `_bucket`, `_count`, `_sum` variants
  - Example query for avg latency: `rate(sample_app_http_server_request_duration_ms_milliseconds_sum[5m]) / rate(sample_app_http_server_request_duration_ms_milliseconds_count[5m])`

- **`sample_app_http_server_active_requests`** - Current number of active requests
  - Example query: `sample_app_http_server_active_requests`

### Runtime Metrics
- **`sample_app_process_runtime_goroutines`** - Number of goroutines
  - Example query: `sample_app_process_runtime_goroutines`

- **`sample_app_process_runtime_mem_alloc_bytes`** - Current heap allocation in bytes
  - Example query: `sample_app_process_runtime_mem_alloc_bytes / 1024 / 1024` (in MB)

### Common Queries

#### Request Rate (requests per second)
```promql
rate(sample_app_http_server_request_count_total[5m])
```

#### Error Rate (percentage)
```promql
(
  rate(sample_app_http_server_request_count_total{error="true"}[5m]) / 
  rate(sample_app_http_server_request_count_total[5m])
) * 100
```

#### 95th Percentile Latency
```promql
histogram_quantile(0.95, rate(sample_app_http_server_request_duration_ms_milliseconds_bucket[5m]))
```

#### Success Rate by Route
```promql
rate(sample_app_http_server_request_count_total{error="false"}[5m]) by (http_route)
```

## Dashboard Panels Description

The pre-configured Grafana dashboard includes these panels:

### 📊 **Request Rate**
- **Query**: `rate(sample_app_http_server_request_count_total[5m])`
- **Shows**: HTTP requests per second, grouped by route and status code
- **Use**: Monitor traffic patterns and request volume

### 🚨 **Error Rate** 
- **Query**: `(rate(sample_app_http_server_request_count_total{error="true"}[5m]) / rate(sample_app_http_server_request_count_total[5m])) * 100`
- **Shows**: Percentage of failed requests over time
- **Use**: Track application reliability and error trends

### ⏱️ **Response Time Percentiles**
- **Queries**: 
  - 50th: `histogram_quantile(0.50, rate(sample_app_http_server_request_duration_ms_milliseconds_bucket[5m]))`
  - 95th: `histogram_quantile(0.95, rate(sample_app_http_server_request_duration_ms_milliseconds_bucket[5m]))`
  - 99th: `histogram_quantile(0.99, rate(sample_app_http_server_request_duration_ms_milliseconds_bucket[5m]))`
- **Shows**: Request latency distribution over time
- **Use**: Monitor performance and identify latency spikes

### 🔄 **Active Requests**
- **Query**: `sample_app_http_server_active_requests`
- **Shows**: Current number of requests being processed
- **Use**: Monitor concurrent load and potential bottlenecks

### 🧵 **Runtime Goroutines**
- **Query**: `sample_app_process_runtime_goroutines`
- **Shows**: Number of Go goroutines
- **Use**: Monitor Go runtime behavior and potential goroutine leaks

### 💾 **Memory Allocation**
- **Query**: `sample_app_process_runtime_mem_alloc_bytes / 1024 / 1024`
- **Shows**: Current heap memory allocation in MB
- **Use**: Track memory usage and identify memory leaks

### 📈 **Key Metrics Summary**
- **Combines**: Total RPS, Error Rate %, 95th Latency, Active Requests
- **Shows**: Critical KPIs in a single view
- **Use**: Quick overview of application health

## Troubleshooting

### 1. Check if all services are running
```bash
docker-compose ps
```

### 2. Verify OTEL Collector connectivity
```bash
# Test OTEL HTTP endpoint
curl -v http://localhost:4318/v1/metrics

# Check collector logs
docker-compose logs otel-collector --tail=20
```

### 3. Check Go application connectivity
```bash
# Test app endpoints
curl http://localhost:8090/healthz
curl http://localhost:8090/work
```

### 4. Verify metrics in Prometheus
```bash
# Check if metrics exist
curl -s http://localhost:9090/api/v1/label/__name__/values | grep sample_app

# Query specific metric
curl -s "http://localhost:9090/api/v1/query?query=sample_app_http_server_request_count_total"
```

### 5. Debug metric flow
```bash
# Watch collector receive metrics in real-time
docker-compose logs -f otel-collector | grep -E "(http\.server\.request|process\.runtime)"
```

### Common Issues

#### "Connection refused" when running Go app
- Ensure OTEL Collector is running: `docker-compose ps`
- Check collector logs: `docker-compose logs otel-collector`

#### No metrics in Prometheus
- Verify collector is exporting to Prometheus: check collector logs
- Check Prometheus scrape targets: http://localhost:9090/targets

#### Go app not starting
- Check if port 8090 is available: `netstat -tlnp | grep 8090`
- Verify `.env` file configuration

#### Datadog Integration Issues

**Metrics not appearing in Datadog**:
```bash
# Check if DD_ENABLED is set to true
echo $DD_ENABLED

# Verify API key is set (should not be empty)
echo $DD_API_KEY | head -c 10

# Check application logs for authentication errors
grep -i "datadog\|error\|failed" application.log
```

**Connection issues**:
```bash
# Test connectivity to Datadog OTLP endpoint
curl -v https://otlp-http.datadoghq.com/v1/metrics

# Check DNS resolution
nslookup otlp-http.datadoghq.com
```

**Wrong Datadog site**:
- Verify `DD_SITE` matches your Datadog account region
- US1: `datadoghq.com`, EU: `datadoghq.eu`, US3: `us3.datadoghq.com`

## 📁 Project Structure

```
go-sample-metric/
├── 🐳 Docker Configuration
│   ├── Dockerfile                 # Multi-stage Go app build
│   ├── docker-compose.yml         # Complete service orchestration
│   ├── .dockerignore              # Build optimization
│   └── .env.docker                # Docker environment config
├── 🚀 Application
│   ├── main.go                    # Go application with OTEL metrics
│   ├── go.mod                     # Go dependencies
│   └── go.sum                     # Dependency checksums
├── ⚙️ Configuration
│   ├── .env.example               # Local development template
│   ├── .env.datadog               # Datadog integration template
│   ├── otel-collector.yaml        # OTEL Collector configuration
│   └── prometheus.yml             # Prometheus scrape config
├── 📊 Monitoring
│   └── grafana/provisioning/
│       ├── dashboards/
│       │   ├── dashboard.yml      # Dashboard auto-loading config
│       │   └── go-sample-metrics.json  # Pre-built dashboard
│       └── datasources/
│           └── prometheus.yml     # Prometheus datasource config
├── 🧪 Testing & Scripts
│   ├── start-docker.sh           # Complete Docker startup script
│   ├── start-demo.sh             # Traditional monitoring stack
│   ├── test-datadog.sh           # Comprehensive Datadog test
│   ├── test-datadog-quick.sh     # Quick Datadog validation
│   └── test-load.sh              # Load testing script
└── 📚 Documentation
    ├── README.md                  # This file - complete guide
    ├── DOCKER_GUIDE.md            # Detailed Docker documentation
    ├── DATADOG_INTEGRATION.md     # Datadog setup guide
    └── TEST_SCRIPTS.md            # Testing documentation
```

## 🆕 What's New - Docker Integration

This project now includes complete Docker support with the following improvements:

### ✨ **New Features Added**
- 🐳 **Complete Docker Compose setup** - Start everything with one command
- 🏥 **Health checks** for all services with proper dependency management
- 🔧 **Multi-stage Docker build** for optimized Go application images
- 📝 **Environment-based configuration** with Docker-specific settings
- 🚀 **Startup scripts** with cleanup handling and error management
- 📖 **Comprehensive documentation** including Docker guide and troubleshooting
- 🔒 **Security improvements** with non-root user in containers
- 🌐 **Proper networking** between all services

### 🎯 **Key Benefits**
- **Zero-configuration startup** - Just run `docker compose up --build`
- **Consistent environments** - Same setup across development, testing, and production
- **Easy debugging** - All logs accessible via `docker compose logs`
- **Resource management** - Controlled resource usage with limits and health checks
- **Development friendly** - Hot-reload support with local development mode

### 🔄 **Migration from Previous Setup**
If you were using the previous manual setup:

```bash
# Old way
./start-demo.sh
go run main.go

# New way - everything in Docker
docker compose up --build

# Or hybrid - monitoring in Docker, app local for development
docker compose up prometheus otel-collector grafana -d
go run main.go
```

## 🛑 Stopping the Services

### Docker Compose
```bash
# Stop all services (graceful)
docker compose down

# Stop and remove volumes (clean slate)
docker compose down -v

# Stop and remove everything including images
docker compose down --rmi all -v

# Force stop if services are unresponsive
docker compose kill && docker compose down
```

### Local Development
```bash
# Stop monitoring stack (if running via Docker)
docker compose down

# Stop Go application
Ctrl+C (if running in foreground)
# or
pkill -f "go run main.go"
# or  
pkill -f "./sample-metric"
```

### Quick Commands
```bash
# View what's running
docker compose ps

# Stop specific service
docker compose stop go-sample-metric

# Restart specific service
docker compose restart go-sample-metric

# View resource usage
docker compose top
```

## 🌐 Service URLs

### Docker Compose Mode
- **Go Application**: http://localhost:8080
  - Health: http://localhost:8080/healthz
  - Work endpoint: http://localhost:8080/work
- **Grafana Dashboard**: http://localhost:3000 (admin/admin)
- **Prometheus**: http://localhost:9090
- **OTEL Collector**: http://localhost:4318 (HTTP), localhost:4317 (gRPC)

### Local Development Mode  
- **Go Application**: http://localhost:8091 (default from .env)
  - Health: http://localhost:8091/healthz
  - Work endpoint: http://localhost:8091/work
- **Grafana Dashboard**: http://localhost:3000 (admin/admin) - from Docker
- **Prometheus**: http://localhost:9090 - from Docker
- **OTEL Collector**: http://localhost:4318 (HTTP), localhost:4317 (gRPC) - from Docker

### Datadog Mode
- **Go Application**: http://localhost:8091 (local) or http://localhost:8080 (Docker)
- **Datadog Dashboard**: https://app.datadoghq.com
  - Navigate to Metrics → Summary to view exported metrics

## Service URLs

- **Go Application**: http://localhost:8090 (default port, configurable via `PORT` env var)
  - Health: http://localhost:8090/healthz
  - Work simulation: http://localhost:8090/work
- **Grafana Dashboard**: http://localhost:3000 (admin/admin) - Local development only
  - Pre-configured dashboard: **"Go Sample Metrics - OpenTelemetry Dashboard"**
- **Prometheus**: http://localhost:9090 - Local development only
  - Query interface for raw metrics
- **OTEL Collector**: http://localhost:4318 (HTTP), localhost:4317 (gRPC) - Local development only
  - Receiving metrics from Go application
- **Datadog**: https://app.datadoghq.com - When using direct Datadog export
  - Metrics → Summary to view exported metrics