package main

import (
	"context"
	"crypto/tls"
	"errors"
	"fmt"
	"log"
	"math/rand"
	"net/http"
	"os"
	"os/signal"
	"runtime"
	"strconv"
	"strings"
	"syscall"
	"time"

	"github.com/joho/godotenv"

	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/exporters/otlp/otlpmetric/otlpmetricgrpc"
	"go.opentelemetry.io/otel/exporters/otlp/otlpmetric/otlpmetrichttp"
	"go.opentelemetry.io/otel/metric"
	sdkmetric "go.opentelemetry.io/otel/sdk/metric"
	"go.opentelemetry.io/otel/sdk/resource"
	semconv "go.opentelemetry.io/otel/semconv/v1.37.0"
	"google.golang.org/grpc/credentials"
)

// Environment variables
const (
	envServiceName    = "SERVICE_NAME"
	envServiceEnv     = "SERVICE_ENV"
	envServiceApp     = "SERVICE_APP"
	envServiceVersion = "SERVICE_VERSION"
	envMetricsURL     = "OTEL_EXPORTER_OTLP_METRICS_ENDPOINT" // e.g. http://localhost:4318/v1/metrics
	envPort           = "PORT"
	envExportInterval = "METRIC_EXPORT_INTERVAL" // duration, e.g. 5s
	envExportTimeout  = "METRIC_EXPORT_TIMEOUT"  // duration, e.g. 10s
	envWorkMinLatency = "WORK_MIN_LATENCY_MS"    // int ms
	envWorkMaxLatency = "WORK_MAX_LATENCY_MS"    // int ms
	envErrorRatePct   = "ERROR_RATE_PERCENT"     // int percent 0-100
	envShutdownTO     = "SHUTDOWN_TIMEOUT"       // duration, e.g. 5s

	// Datadog specific settings
	envDatadogAPIKey  = "DD_API_KEY"    // Datadog API key
	envDatadogSite    = "DD_SITE"       // Datadog site (e.g. datadoghq.com, datadoghq.eu)
	envDatadogEnabled = "DD_ENABLED"    // Enable Datadog direct export (true/false)
	envExporterType   = "EXPORTER_TYPE" // http, grpc, or datadog
)

func getEnv(key, def string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return def
}

// App level state for metrics updates
var (
	coldStart  = time.Now()
	buildStart = time.Now().Unix() // naive build timestamp
)

// config holds runtime configuration derived from environment variables.
type config struct {
	ServiceName      string
	ServiceEnv       string
	ServiceApp       string
	ServiceVersion   string
	MetricsEndpoint  string
	Port             string
	ExportInterval   time.Duration
	ExportTimeout    time.Duration
	WorkMinLatencyMS int
	WorkMaxLatencyMS int
	ErrorRatePercent int
	ShutdownTimeout  time.Duration

	// Datadog specific settings
	DatadogAPIKey  string
	DatadogSite    string
	DatadogEnabled bool
	ExporterType   string
}

func loadConfig() config {
	// helpers
	parseDuration := func(key, def string) time.Duration {
		v := getEnv(key, def)
		d, err := time.ParseDuration(v)
		if err != nil {
			log.Printf("invalid duration for %s=%q using default %s", key, v, def)
			d, _ = time.ParseDuration(def)
		}
		return d
	}
	parseInt := func(key string, def int) int {
		v := getEnv(key, "")
		if strings.TrimSpace(v) == "" {
			return def
		}
		i, err := strconv.Atoi(v)
		if err != nil {
			log.Printf("invalid int for %s=%q using default %d", key, v, def)
			return def
		}
		return i
	}

	cfg := config{
		ServiceName:      getEnv(envServiceName, "sample-metric-service"),
		ServiceEnv:       getEnv(envServiceEnv, "development"),
		ServiceApp:       getEnv(envServiceApp, "demo"),
		ServiceVersion:   getEnv(envServiceVersion, "0.1.0"),
		MetricsEndpoint:  getEnv(envMetricsURL, "http://localhost:9529/v1/metrics"),
		Port:             getEnv(envPort, "8090"),
		ExportInterval:   parseDuration(envExportInterval, "5s"),
		ExportTimeout:    parseDuration(envExportTimeout, "10s"),
		WorkMinLatencyMS: parseInt(envWorkMinLatency, 50),
		WorkMaxLatencyMS: parseInt(envWorkMaxLatency, 300),
		ErrorRatePercent: parseInt(envErrorRatePct, 10),
		ShutdownTimeout:  parseDuration(envShutdownTO, "5s"),

		// Datadog specific settings
		DatadogAPIKey:  getEnv(envDatadogAPIKey, ""),
		DatadogSite:    getEnv(envDatadogSite, "datadoghq.com"),
		DatadogEnabled: strings.ToLower(getEnv(envDatadogEnabled, "false")) == "true",
		ExporterType:   getEnv(envExporterType, "http"),
	}
	// basic validation / normalization
	if cfg.WorkMaxLatencyMS < cfg.WorkMinLatencyMS {
		cfg.WorkMaxLatencyMS = cfg.WorkMinLatencyMS
	}
	if cfg.ErrorRatePercent < 0 {
		cfg.ErrorRatePercent = 0
	}
	if cfg.ErrorRatePercent > 100 {
		cfg.ErrorRatePercent = 100
	}

	// Configure Datadog endpoint if enabled
	if cfg.DatadogEnabled && cfg.DatadogAPIKey != "" {
		if cfg.ExporterType == "grpc" {
			cfg.MetricsEndpoint = fmt.Sprintf("https://otlp.%s:443", cfg.DatadogSite)
		} else {
			cfg.MetricsEndpoint = fmt.Sprintf("https://otlp-http.%s/v1/metrics", cfg.DatadogSite)
		}
	}

	return cfg
}

// setupMeterProvider configures the global MeterProvider with OTLP exporter.
// Supports both HTTP and gRPC exporters with Datadog authentication.
func setupMeterProvider(ctx context.Context, cfg config) (*sdkmetric.MeterProvider, error) {
	var exporter sdkmetric.Exporter
	var err error

	if cfg.ExporterType == "grpc" {
		// gRPC exporter setup
		opts := []otlpmetricgrpc.Option{
			otlpmetricgrpc.WithEndpointURL(cfg.MetricsEndpoint),
		}

		// Add Datadog API key authentication if enabled
		if cfg.DatadogEnabled && cfg.DatadogAPIKey != "" {
			opts = append(opts,
				otlpmetricgrpc.WithHeaders(map[string]string{
					"dd-api-key": cfg.DatadogAPIKey,
				}),
				otlpmetricgrpc.WithTLSCredentials(credentials.NewTLS(&tls.Config{})),
			)
		}

		exporter, err = otlpmetricgrpc.New(ctx, opts...)
	} else {
		// HTTP exporter setup (default)
		opts := []otlpmetrichttp.Option{
			otlpmetrichttp.WithEndpointURL(cfg.MetricsEndpoint),
			otlpmetrichttp.WithCompression(otlpmetrichttp.GzipCompression),
		}

		// Add Datadog API key authentication if enabled
		if cfg.DatadogEnabled && cfg.DatadogAPIKey != "" {
			opts = append(opts, otlpmetrichttp.WithHeaders(map[string]string{
				"dd-api-key": cfg.DatadogAPIKey,
			}))
		}

		exporter, err = otlpmetrichttp.New(ctx, opts...)
	}

	if err != nil {
		return nil, fmt.Errorf("create metric exporter: %w", err)
	}

	res, err := resource.New(ctx,
		resource.WithFromEnv(),
		resource.WithHost(),
		resource.WithTelemetrySDK(),
		resource.WithAttributes(
			semconv.ServiceNameKey.String(cfg.ServiceName),
			semconv.ServiceVersionKey.String(cfg.ServiceVersion),
			semconv.DeploymentEnvironmentName(cfg.ServiceEnv),
			attribute.String("service.app", cfg.ServiceApp),
			attribute.Int64("process.start_unix", coldStart.Unix()),
			attribute.Int64("build.start_unix", buildStart),
		),
	)
	if err != nil {
		return nil, fmt.Errorf("create resource: %w", err)
	}

	// Use a periodic reader with configured interval / timeout
	reader := sdkmetric.NewPeriodicReader(exporter,
		sdkmetric.WithInterval(cfg.ExportInterval),
		sdkmetric.WithTimeout(cfg.ExportTimeout),
	)

	mp := sdkmetric.NewMeterProvider(
		sdkmetric.WithResource(res),
		sdkmetric.WithReader(reader),
	)
	otel.SetMeterProvider(mp)
	return mp, nil
}

// registerInstruments defines and returns instruments used by handlers.
type instruments struct {
	requestCounter  metric.Int64Counter
	latencyHist     metric.Float64Histogram
	activeReqUpDown metric.Int64UpDownCounter
	cpuGauge        metric.Float64ObservableGauge
	memGauge        metric.Int64ObservableGauge
}

func newInstruments() (instruments, error) {
	meter := otel.Meter("sample-metric")
	var inst instruments
	var err error
	if inst.requestCounter, err = meter.Int64Counter("http.server.request.count",
		metric.WithDescription("Total number of received HTTP requests")); err != nil {
		return inst, err
	}
	if inst.latencyHist, err = meter.Float64Histogram("http.server.request.duration.ms",
		metric.WithUnit("ms"),
		metric.WithDescription("Request latency in milliseconds")); err != nil {
		return inst, err
	}
	if inst.activeReqUpDown, err = meter.Int64UpDownCounter("http.server.active_requests",
		metric.WithDescription("Current number of in-flight requests")); err != nil {
		return inst, err
	}

	if inst.cpuGauge, err = meter.Float64ObservableGauge("process.runtime.goroutines",
		metric.WithDescription("Number of goroutines")); err != nil {
		return inst, err
	}
	if inst.memGauge, err = meter.Int64ObservableGauge("process.runtime.mem.alloc.bytes",
		metric.WithDescription("Current heap allocation in bytes")); err != nil {
		return inst, err
	}

	_, err = meter.RegisterCallback(func(ctx context.Context, o metric.Observer) error {
		var ms runtime.MemStats
		runtime.ReadMemStats(&ms)
		o.ObserveFloat64(inst.cpuGauge, float64(runtime.NumGoroutine()))
		o.ObserveInt64(inst.memGauge, int64(ms.Alloc))
		return nil
	}, inst.cpuGauge, inst.memGauge)
	if err != nil {
		return inst, err
	}
	return inst, nil
}

func main() {
	// Load .env file if present (ignore error if absent)
	_ = godotenv.Load()
	cfg := loadConfig()
	log.Printf("starting service name=%s env=%s app=%s ver=%s port=%s exporter=%s metrics_endpoint=%s export_int=%s export_timeout=%s work_latency_ms=[%d,%d] error_rate=%d%% datadog_enabled=%t",
		cfg.ServiceName, cfg.ServiceEnv, cfg.ServiceApp, cfg.ServiceVersion, cfg.Port, cfg.ExporterType, cfg.MetricsEndpoint, cfg.ExportInterval, cfg.ExportTimeout, cfg.WorkMinLatencyMS, cfg.WorkMaxLatencyMS, cfg.ErrorRatePercent, cfg.DatadogEnabled)

	ctx, cancel := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer cancel()

	mp, err := setupMeterProvider(ctx, cfg)
	if err != nil {
		log.Fatalf("failed to set up meter provider: %v", err)
	}
	defer func() {
		// Allow a short grace period for final export
		shutdownCtx, c := context.WithTimeout(context.Background(), 5*time.Second)
		defer c()
		if err := mp.Shutdown(shutdownCtx); err != nil && !errors.Is(err, context.DeadlineExceeded) {
			log.Printf("metric provider shutdown error: %v", err)
		}
	}()

	inst, err := newInstruments()
	if err != nil {
		log.Fatalf("failed creating instruments: %v", err)
	}

	mux := http.NewServeMux()
	mux.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte("ok"))
	})
	mux.HandleFunc("/work", func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		inst.activeReqUpDown.Add(r.Context(), 1)
		defer inst.activeReqUpDown.Add(r.Context(), -1)

		// Simulate variable work using configured latency range
		rangeSpan := cfg.WorkMaxLatencyMS - cfg.WorkMinLatencyMS
		var add int
		if rangeSpan > 0 {
			add = rand.Intn(rangeSpan + 1)
		}
		simulated := time.Duration(cfg.WorkMinLatencyMS+add) * time.Millisecond
		time.Sleep(simulated)

		// Simulated error path for dimension variety
		statusCode := http.StatusOK
		var errAttr attribute.KeyValue
		if cfg.ErrorRatePercent > 0 && rand.Intn(100) < cfg.ErrorRatePercent {
			statusCode = http.StatusInternalServerError
			errAttr = attribute.String("error", "true")
		} else {
			errAttr = attribute.String("error", "false")
		}

		attrs := []attribute.KeyValue{
			attribute.String("http.route", "/work"),
			attribute.Int("http.status_code", statusCode),
			errAttr,
		}
		inst.requestCounter.Add(r.Context(), 1, metric.WithAttributes(attrs...))
		inst.latencyHist.Record(r.Context(), float64(time.Since(start).Milliseconds()), metric.WithAttributes(attrs...))

		w.Header().Set("Content-Type", "text/plain")
		w.WriteHeader(statusCode)
		fmt.Fprintf(w, "work simulated: %s\n", simulated)
	})

	srv := &http.Server{Addr: ":" + cfg.Port, Handler: mux}
	log.Printf("sample metric service listening on :%s (exporting to %s)", cfg.Port, cfg.MetricsEndpoint)

	go func() {
		if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			log.Fatalf("server error: %v", err)
		}
	}()

	<-ctx.Done()
	shutdownCtx, cancelSrv := context.WithTimeout(context.Background(), cfg.ShutdownTimeout)
	defer cancelSrv()
	_ = srv.Shutdown(shutdownCtx)
	log.Println("server gracefully stopped")
}
