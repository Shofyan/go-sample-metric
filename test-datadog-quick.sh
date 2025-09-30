#!/bin/bash

# Quick Datadog integration test
# A simplified version for basic validation

echo "🧪 Quick Datadog Integration Test"
echo "================================="

# Check if binary exists
if [ ! -f "sample-metric" ]; then
    echo "Building application..."
    go build -o sample-metric . || exit 1
    echo "✅ Build successful"
fi

# Test 1: Datadog HTTP configuration
echo ""
echo "Test 1: Datadog HTTP Export"
echo "Setting: DD_ENABLED=true, DD_SITE=datadoghq.com, EXPORTER_TYPE=http"

DD_ENABLED=true \
DD_API_KEY=test-key-validation \
DD_SITE=datadoghq.com \
EXPORTER_TYPE=http \
SERVICE_NAME=test-service \
PORT=8094 \
timeout 5s ./sample-metric &

APP_PID=$!
sleep 3

# Check if app is running
if kill -0 $APP_PID 2>/dev/null; then
    echo "✅ Application started successfully with Datadog HTTP config"
    
    # Test endpoints
    if curl -s http://localhost:8094/healthz | grep -q "ok"; then
        echo "✅ Health endpoint working"
    else
        echo "❌ Health endpoint failed"
    fi
    
    if curl -s http://localhost:8094/work | grep -q "work simulated"; then
        echo "✅ Work endpoint working"
    else
        echo "❌ Work endpoint failed"
    fi
    
    kill $APP_PID 2>/dev/null
    wait $APP_PID 2>/dev/null
else
    echo "❌ Application failed to start with Datadog config"
fi

# Test 2: Local development configuration  
echo ""
echo "Test 2: Local Development Mode"
echo "Setting: DD_ENABLED=false"

DD_ENABLED=false \
OTEL_EXPORTER_OTLP_METRICS_ENDPOINT=http://localhost:4318/v1/metrics \
SERVICE_NAME=test-service \
PORT=8094 \
timeout 5s ./sample-metric &

APP_PID=$!
sleep 3

if kill -0 $APP_PID 2>/dev/null; then
    echo "✅ Application started successfully with local config"
    kill $APP_PID 2>/dev/null
    wait $APP_PID 2>/dev/null
else
    echo "❌ Application failed to start with local config"
fi

echo ""
echo "🎉 Quick test completed!"
echo ""
echo "Next steps:"
echo "1. Set your real DD_API_KEY in .env file"
echo "2. Run: cp .env.datadog .env"
echo "3. Edit .env with your API key"
echo "4. Run: ./sample-metric"
echo "5. Generate traffic: ./test-load.sh"
echo "6. Check Datadog → Metrics → Summary"