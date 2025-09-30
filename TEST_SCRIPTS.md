# Datadog Integration Test Scripts

## Overview
Two test scripts are provided to validate the Datadog integration:

### `test-datadog-quick.sh` - Quick Validation
Fast test for basic functionality validation.

**Usage:**
```bash
chmod +x test-datadog-quick.sh
./test-datadog-quick.sh
```

**What it tests:**
- Application builds successfully
- Datadog HTTP exporter configuration
- Local development mode
- Basic endpoint functionality
- Configuration validation

**Duration:** ~10 seconds

---

### `test-datadog.sh` - Comprehensive Test Suite
Thorough validation of all Datadog integration features.

**Usage:**
```bash
chmod +x test-datadog.sh
./test-datadog.sh
```

**What it tests:**
- Multiple Datadog sites (US1, EU)
- Both HTTP and gRPC exporters
- Endpoint configuration validation
- Traffic generation
- Configuration validation
- Local development mode
- Error handling and cleanup

**Duration:** ~30-60 seconds

---

## Test Output Examples

### Successful Quick Test Output:
```
🧪 Quick Datadog Integration Test
=================================

✅ Build successful

Test 1: Datadog HTTP Export
Setting: DD_ENABLED=true, DD_SITE=datadoghq.com, EXPORTER_TYPE=http
✅ Application started successfully with Datadog HTTP config
✅ Health endpoint working
✅ Work endpoint working

Test 2: Local Development Mode
Setting: DD_ENABLED=false
✅ Application started successfully with local config

🎉 Quick test completed!
```

### Successful Comprehensive Test Output:
```
===============================================
   Datadog Integration Test Suite
===============================================

[INFO] Checking prerequisites...
[SUCCESS] Application binary found

=== Test 1: Datadog HTTP Exporter (US1) ===
[SUCCESS] Correct Datadog endpoint configured: https://otlp-http.datadoghq.com/v1/metrics
[SUCCESS] Application is responding on port 8093
[SUCCESS] Health endpoint working correctly
[SUCCESS] Work endpoint working correctly
[SUCCESS] Generated 10 test requests
[SUCCESS] Datadog configuration test completed successfully

=== Test 2: Datadog gRPC Exporter (EU) ===
[SUCCESS] Correct Datadog endpoint configured: https://otlp.datadoghq.eu:443
[SUCCESS] Datadog configuration test completed successfully

=== Test 3: Local Development Mode ===
[SUCCESS] Local development mode enabled correctly
[SUCCESS] Local development mode test completed

=== Test 4: Configuration Validation ===
[SUCCESS] Configuration validation tests completed

[SUCCESS] ===============================================
[SUCCESS]    All Datadog Integration Tests Passed!
[SUCCESS] ===============================================
```

---

## Troubleshooting Test Issues

### Common Issues:

**Port already in use:**
```
[ERROR] Port 8093 is already in use
```
*Solution:* Stop any running applications on the test ports or wait for them to finish.

**Build failures:**
```
[ERROR] Failed to build application
```
*Solution:* Ensure Go is properly installed and dependencies are available.

**Application startup failures:**
```
[ERROR] Application failed to start with Datadog config
```
*Solution:* Check the test output logs for specific error messages.

### Manual Testing:

If automated tests fail, you can manually test with:

```bash
# Build the app
go build -o sample-metric .

# Test Datadog config
DD_ENABLED=true DD_API_KEY=test-key DD_SITE=datadoghq.com ./sample-metric

# In another terminal:
curl http://localhost:8090/healthz
curl http://localhost:8090/work
```

---

## Integration with CI/CD

These scripts can be used in CI/CD pipelines:

```yaml
# Example GitHub Actions step
- name: Test Datadog Integration
  run: |
    chmod +x test-datadog-quick.sh
    ./test-datadog-quick.sh
```

```yaml
# Example comprehensive test
- name: Comprehensive Datadog Test
  run: |
    chmod +x test-datadog.sh
    ./test-datadog.sh
```