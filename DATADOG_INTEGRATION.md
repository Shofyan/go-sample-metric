# Datadog Integ### 3. Configuration Files
- **`.env.example`**: Updated with Datadog configuration options
- **`.env.datadog`**: New file with Datadog-specific configuration template
- **`test-datadog.sh`**: Comprehensive test script for validating Datadog integration
- **`test-datadog-quick.sh`**: Quick validation test for basic functionalityon Update Summary

## What was updated

### 1. Go Application (`main.go`)
- Added support for direct Datadog OTLP export
- Added both HTTP and gRPC OTLP exporters
- Added Datadog-specific environment variables:
  - `DD_ENABLED`: Enable/disable Datadog export
  - `DD_API_KEY`: Datadog API key for authentication
  - `DD_SITE`: Datadog site/region configuration
  - `EXPORTER_TYPE`: Choose between HTTP or gRPC exporters
- Automatic endpoint configuration based on Datadog site
- Enhanced logging to show current configuration

### 2. Configuration Files
- **`.env.example`**: Updated with Datadog configuration options
- **`.env.datadog`**: New file with Datadog-specific configuration template
- **`test-datadog.sh`**: New test script for validating Datadog integration

### 3. Dependencies (`go.mod`)
- Added `go.opentelemetry.io/otel/exporters/otlp/otlpmetric/otlpmetricgrpc`
- Updated existing OpenTelemetry dependencies to latest versions

### 4. README (`README.md`)
- Updated title and description to highlight Datadog support
- Added "Building and Running" section with prerequisites
- Enhanced Quick Demo with detailed Datadog setup steps
- Updated Architecture section showing both deployment modes
- Expanded environment variables table with Datadog options
- Added configuration files comparison table
- Enhanced troubleshooting section with Datadog-specific issues
- Updated service URLs with more accurate information

## Usage Modes

### Mode 1: Direct Datadog Export (Production)
```bash
cp .env.datadog .env
# Edit .env with your DD_API_KEY
go run main.go
```

### Mode 2: Local Development Stack
```bash
cp .env.example .env
./start-demo.sh
go run main.go
```

## Key Features Added

1. **Zero-infrastructure deployment**: Send metrics directly to Datadog without local collector
2. **Multi-region support**: Automatic endpoint configuration for different Datadog sites
3. **Flexible exporters**: Choose between HTTP or gRPC protocols
4. **Enhanced configuration**: Clear separation between development and production configs
5. **Better documentation**: Step-by-step setup guides and troubleshooting

## Configuration Priority

When `DD_ENABLED=true`:
1. Datadog endpoints are automatically configured based on `DD_SITE`
2. API key authentication is added to requests
3. Custom `OTEL_EXPORTER_OTLP_METRICS_ENDPOINT` is ignored

When `DD_ENABLED=false` (default):
1. Uses custom endpoint from `OTEL_EXPORTER_OTLP_METRICS_ENDPOINT`
2. No authentication headers are added
3. Suitable for local development with OTEL Collector

## Supported Datadog Sites

- US1: `datadoghq.com` (default)
- EU: `datadoghq.eu`  
- US3: `us3.datadoghq.com`
- US5: `us5.datadoghq.com`
- AP1: `ap1.datadoghq.com`

## Metrics in Datadog

Metrics will appear with the prefix `otel.` and include tags:
- `service.name`
- `service.version`
- `service.env`
- `http.route`
- `http.status_code`
- `error` (true/false)