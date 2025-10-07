# Docker Setup Guide

This guide explains how to run the Go Sample Metric application using Docker and Docker Compose.

## Quick Start

### Option 1: Using the startup script (Recommended)
```bash
./start-docker.sh
```

### Option 2: Using Docker Compose directly
```bash
# Build and start all services
docker compose up --build

# Or run in background
docker compose up --build -d
```

## Services Overview

The Docker Compose setup includes the following services:

| Service | Port | Description |
|---------|------|-------------|
| **go-sample-metric** | 8080 | The main Go application |
| **otel-collector** | 4317, 4318, 8889 | OpenTelemetry Collector |
| **prometheus** | 9090 | Metrics storage and querying |
| **grafana** | 3000 | Metrics visualization dashboard |

## Service URLs

Once all services are running, you can access:

- **Go Application**: http://localhost:8080
  - Health check: http://localhost:8080/healthz
  - Metrics: http://localhost:8080/metrics
- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3000 (admin/admin)

## Configuration

The application uses environment variables for configuration. The Docker setup uses `.env.docker` file:

```bash
# Copy and modify the environment file if needed
cp .env.docker .env.docker.local
# Edit .env.docker.local with your settings
```

Key environment variables:
- `SERVICE_NAME`: Name of the service
- `OTEL_EXPORTER_OTLP_METRICS_ENDPOINT`: OTLP endpoint for metrics
- `PORT`: Application port
- `METRIC_EXPORT_INTERVAL`: How often to export metrics
- `ERROR_RATE_PERCENT`: Simulated error rate percentage

## Development Workflow

### Building the application
```bash
# Build only the Go application
docker compose build go-sample-metric

# Rebuild without cache
docker compose build --no-cache go-sample-metric
```

### Running services individually
```bash
# Start only Prometheus and OTEL Collector
docker compose up prometheus otel-collector

# Start the Go application
docker compose up go-sample-metric
```

### Viewing logs
```bash
# View all logs
docker compose logs

# View logs for a specific service
docker compose logs go-sample-metric

# Follow logs in real-time
docker compose logs -f go-sample-metric
```

### Stopping services
```bash
# Stop all services
docker compose down

# Stop and remove volumes
docker compose down -v

# Stop and remove everything including images
docker compose down --rmi all -v
```

## Health Checks

The Go application includes health checks:
- **Endpoint**: `/healthz`
- **Interval**: 30 seconds
- **Timeout**: 10 seconds
- **Retries**: 3

Check service health:
```bash
# Check if the application is healthy
curl http://localhost:8080/healthz

# Check Docker health status
docker compose ps
```

## Troubleshooting

### Application won't start
1. Check if all required ports are available:
   ```bash
   # Check if ports are in use
   lsof -i :8080,9090,3000,4317,4318
   ```

2. Check service logs:
   ```bash
   docker compose logs go-sample-metric
   ```

3. Verify environment configuration:
   ```bash
   docker compose config
   ```

### Metrics not appearing
1. Check if OTEL Collector is receiving metrics:
   ```bash
   curl http://localhost:8889/metrics
   ```

2. Check Prometheus targets:
   - Go to http://localhost:9090/targets
   - Verify all targets are UP

3. Check application metrics endpoint:
   ```bash
   curl http://localhost:8080/metrics
   ```

### Clean restart
```bash
# Complete cleanup and restart
docker compose down -v --rmi all
docker compose up --build
```

## File Structure

```
.
├── Dockerfile              # Multi-stage Docker build
├── docker-compose.yml      # Service orchestration
├── .dockerignore           # Docker build context exclusions
├── .env.docker             # Docker environment variables
├── start-docker.sh         # Startup script
├── otel-collector.yaml     # OTEL Collector configuration
├── prometheus.yml          # Prometheus configuration
└── grafana/                # Grafana provisioning
    └── provisioning/
        ├── dashboards/
        └── datasources/
```

## Performance Tips

1. **Use BuildKit for faster builds**:
   ```bash
   export DOCKER_BUILDKIT=1
   docker compose build
   ```

2. **Use Docker layer caching**:
   The Dockerfile is optimized with proper layer ordering for better caching.

3. **Limit resource usage**:
   ```yaml
   # Add to docker-compose.yml service
   deploy:
     resources:
       limits:
         cpus: '0.5'
         memory: 512M
   ```

## Production Considerations

For production deployment, consider:

1. **Use specific image tags** instead of `latest`
2. **Set resource limits** for all services
3. **Use external volumes** for data persistence
4. **Configure proper logging** with log rotation
5. **Set up monitoring** and alerting
6. **Use secrets management** for sensitive data
7. **Enable TLS** for external endpoints