#!/bin/bash

echo "=== Generating load for metrics demo ==="
echo

# Check if the app is running
if ! curl -s http://localhost:8080/healthz > /dev/null; then
    echo "❌ Go application is not running on port 8080"
    echo "   Please start it first: go run main.go"
    exit 1
fi

echo "✅ Go application is running"
echo "🔄 Generating load..."

# Generate steady load for 2 minutes
end_time=$((SECONDS + 120))

request_count=0
while [ $SECONDS -lt $end_time ]; do
    # Mix of health checks and work requests
    if [ $((request_count % 5)) -eq 0 ]; then
        curl -s http://localhost:8080/healthz > /dev/null
        echo -n "."
    else
        curl -s http://localhost:8080/work > /dev/null
        echo -n "w"
    fi
    
    request_count=$((request_count + 1))
    
    # Random delay between requests
    sleep $(awk 'BEGIN{srand(); print rand() * 2}')
done

echo
echo "✅ Load generation complete!"
echo "📊 Generated approximately $request_count requests"
echo "🔍 Check your metrics in:"
echo "   - Prometheus: http://localhost:9090"
echo "   - Grafana: http://localhost:3000"
echo "   - OTEL Collector logs: docker-compose logs otel-collector"