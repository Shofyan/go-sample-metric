#!/bin/bash

echo "=== Starting OpenTelemetry Collector Demo ==="
echo

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Start the monitoring stack
echo "🚀 Starting monitoring stack (OTEL Collector, Prometheus, Grafana)..."
docker-compose up -d

# Wait for services to be ready
echo "⏳ Waiting for services to start..."
sleep 10

# Check if services are running
echo "🔍 Checking service health..."
if curl -s http://localhost:4318/v1/metrics > /dev/null; then
    echo "✅ OTEL Collector is ready"
else
    echo "❌ OTEL Collector is not ready"
fi

if curl -s http://localhost:9090/-/ready > /dev/null; then
    echo "✅ Prometheus is ready"
else
    echo "❌ Prometheus is not ready"
fi

if curl -s http://localhost:3000/api/health > /dev/null; then
    echo "✅ Grafana is ready"
else
    echo "❌ Grafana is not ready"
fi

echo
echo "🎯 Services are starting up! You can now:"
echo "   1. Run the Go app: go run main.go"
echo "   2. Generate traffic: ./test-load.sh"
echo "   3. View metrics:"
echo "      - Prometheus: http://localhost:9090"
echo "      - Grafana: http://localhost:3000 (admin/admin)"
echo "      - OTEL Collector logs: docker-compose logs -f otel-collector"
echo
echo "🛑 To stop everything: docker-compose down"