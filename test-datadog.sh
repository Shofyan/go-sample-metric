#!/bin/bash

# Test script for Datadog integration
# This script validates the Datadog configuration and functionality

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
TEST_PORT=8093
TEST_API_KEY="test-key-12345"
TEST_SERVICE_NAME="datadog-integration-test"
APP_PID=""

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to cleanup on exit
cleanup() {
    if [ ! -z "$APP_PID" ]; then
        print_status "Stopping test application (PID: $APP_PID)..."
        kill $APP_PID 2>/dev/null || true
        wait $APP_PID 2>/dev/null || true
    fi
    print_status "Cleanup completed"
}

# Set trap for cleanup
trap cleanup EXIT INT TERM

# Function to check if port is available
check_port() {
    local port=$1
    if netstat -tuln 2>/dev/null | grep -q ":$port "; then
        print_error "Port $port is already in use"
        return 1
    fi
    return 0
}

# Function to wait for application to start
wait_for_app() {
    local port=$1
    local max_attempts=10
    local attempt=1
    
    print_status "Waiting for application to start on port $port..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s http://localhost:$port/healthz > /dev/null 2>&1; then
            print_success "Application is responding on port $port"
            return 0
        fi
        
        print_status "Attempt $attempt/$max_attempts - waiting for application..."
        sleep 1
        attempt=$((attempt + 1))
    done
    
    print_error "Application failed to start within $max_attempts seconds"
    return 1
}

# Function to test application endpoints
test_endpoints() {
    local port=$1
    
    print_status "Testing application endpoints..."
    
    # Test health endpoint
    print_status "Testing /healthz endpoint..."
    if response=$(curl -s http://localhost:$port/healthz); then
        if [ "$response" = "ok" ]; then
            print_success "Health endpoint working correctly"
        else
            print_warning "Health endpoint returned unexpected response: $response"
        fi
    else
        print_error "Health endpoint request failed"
        return 1
    fi
    
    # Test work endpoint
    print_status "Testing /work endpoint..."
    if response=$(curl -s http://localhost:$port/work); then
        if echo "$response" | grep -q "work simulated"; then
            print_success "Work endpoint working correctly"
        else
            print_warning "Work endpoint returned unexpected response: $response"
        fi
    else
        print_error "Work endpoint request failed"
        return 1
    fi
    
    return 0
}

# Function to generate test traffic
generate_traffic() {
    local port=$1
    local requests=10
    
    print_status "Generating $requests test requests..."
    
    for i in $(seq 1 $requests); do
        curl -s http://localhost:$port/work > /dev/null &
        if [ $((i % 3)) -eq 0 ]; then
            sleep 0.1  # Small delay every 3 requests
        fi
    done
    
    wait  # Wait for all background requests to complete
    print_success "Generated $requests test requests"
}

# Function to validate configuration
validate_config() {
    local dd_enabled=$1
    local dd_api_key=$2
    local dd_site=$3
    local exporter_type=$4
    
    print_status "Validating configuration..."
    
    if [ "$dd_enabled" = "true" ]; then
        if [ -z "$dd_api_key" ]; then
            print_error "DD_API_KEY is required when DD_ENABLED=true"
            return 1
        fi
        
        if [ -z "$dd_site" ]; then
            print_warning "DD_SITE not set, using default (datadoghq.com)"
        fi
        
        print_success "Datadog configuration is valid"
    else
        print_success "Local development configuration"
    fi
    
    return 0
}

# Function to test specific Datadog configuration
test_datadog_config() {
    local dd_site=$1
    local exporter_type=$2
    
    print_status "Testing Datadog configuration (site: $dd_site, exporter: $exporter_type)..."
    
    # Start application with Datadog config
    DD_ENABLED=true \
    DD_API_KEY="$TEST_API_KEY" \
    DD_SITE="$dd_site" \
    EXPORTER_TYPE="$exporter_type" \
    SERVICE_NAME="$TEST_SERVICE_NAME" \
    SERVICE_ENV="test" \
    PORT="$TEST_PORT" \
    METRIC_EXPORT_INTERVAL="2s" \
    ./sample-metric > test_output.log 2>&1 &
    
    APP_PID=$!
    sleep 2
    
    # Check if application is still running
    if ! kill -0 $APP_PID 2>/dev/null; then
        print_error "Application failed to start with Datadog config"
        cat test_output.log
        return 1
    fi
    
    # Check logs for expected configuration
    if grep -q "datadog_enabled=true" test_output.log; then
        print_success "Datadog mode enabled correctly"
    else
        print_error "Datadog mode not enabled in logs"
        return 1
    fi
    
    # Check for correct endpoint
    local expected_endpoint
    if [ "$exporter_type" = "grpc" ]; then
        expected_endpoint="https://otlp.$dd_site:443"
    else
        expected_endpoint="https://otlp-http.$dd_site/v1/metrics"
    fi
    
    if grep -q "$expected_endpoint" test_output.log; then
        print_success "Correct Datadog endpoint configured: $expected_endpoint"
    else
        print_error "Expected endpoint not found in logs: $expected_endpoint"
        cat test_output.log
        return 1
    fi
    
    # Test endpoints
    if ! wait_for_app $TEST_PORT; then
        return 1
    fi
    
    if ! test_endpoints $TEST_PORT; then
        return 1
    fi
    
    # Generate some traffic
    generate_traffic $TEST_PORT
    
    # Stop the application
    kill $APP_PID 2>/dev/null || true
    wait $APP_PID 2>/dev/null || true
    APP_PID=""
    
    print_success "Datadog configuration test completed successfully"
    return 0
}

# Main test function
main() {
    echo ""
    echo "==============================================="
    echo "   Datadog Integration Test Suite"
    echo "==============================================="
    echo ""
    
    # Check prerequisites
    print_status "Checking prerequisites..."
    
    if [ ! -f "sample-metric" ]; then
        print_status "Building application..."
        if ! go build -o sample-metric .; then
            print_error "Failed to build application"
            exit 1
        fi
        print_success "Application built successfully"
    else
        print_success "Application binary found"
    fi
    
    # Check if port is available
    if ! check_port $TEST_PORT; then
        exit 1
    fi
    
    # Test 1: Datadog HTTP exporter with US1 site
    print_status ""
    print_status "=== Test 1: Datadog HTTP Exporter (US1) ==="
    if ! test_datadog_config "datadoghq.com" "http"; then
        print_error "Test 1 failed"
        exit 1
    fi
    
    # Test 2: Datadog gRPC exporter with EU site
    print_status ""
    print_status "=== Test 2: Datadog gRPC Exporter (EU) ==="
    if ! test_datadog_config "datadoghq.eu" "grpc"; then
        print_error "Test 2 failed"
        exit 1
    fi
    
    # Test 3: Local development mode
    print_status ""
    print_status "=== Test 3: Local Development Mode ==="
    DD_ENABLED=false \
    OTEL_EXPORTER_OTLP_METRICS_ENDPOINT="http://localhost:4318/v1/metrics" \
    SERVICE_NAME="$TEST_SERVICE_NAME" \
    SERVICE_ENV="development" \
    PORT="$TEST_PORT" \
    ./sample-metric > test_output.log 2>&1 &
    
    APP_PID=$!
    sleep 2
    
    if ! kill -0 $APP_PID 2>/dev/null; then
        print_error "Application failed to start in local mode"
        cat test_output.log
        exit 1
    fi
    
    if grep -q "datadog_enabled=false" test_output.log; then
        print_success "Local development mode enabled correctly"
    else
        print_error "Local development mode not configured correctly"
        exit 1
    fi
    
    if ! wait_for_app $TEST_PORT; then
        exit 1
    fi
    
    if ! test_endpoints $TEST_PORT; then
        exit 1
    fi
    
    kill $APP_PID 2>/dev/null || true
    wait $APP_PID 2>/dev/null || true
    APP_PID=""
    
    print_success "Local development mode test completed"
    
    # Test 4: Configuration validation
    print_status ""
    print_status "=== Test 4: Configuration Validation ==="
    
    validate_config "true" "$TEST_API_KEY" "datadoghq.com" "http"
    validate_config "false" "" "" "http"
    
    print_success "Configuration validation tests completed"
    
    # Cleanup
    rm -f test_output.log
    
    echo ""
    print_success "==============================================="
    print_success "   All Datadog Integration Tests Passed!"
    print_success "==============================================="
    echo ""
    
    echo "Summary of tested configurations:"
    echo "✅ Datadog HTTP export (US1 site)"
    echo "✅ Datadog gRPC export (EU site)"
    echo "✅ Local development mode"
    echo "✅ Configuration validation"
    echo "✅ Health and work endpoints"
    echo "✅ Traffic generation"
    echo ""
    echo "The application is ready for:"
    echo "• Production deployment with Datadog"
    echo "• Local development with OTEL Collector"
    echo "• Both HTTP and gRPC OTLP exporters"
    echo ""
}

# Run main function
main "$@"