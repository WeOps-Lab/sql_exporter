package sql_exporter

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"github.com/go-sql-driver/mysql"
	"github.com/prometheus/common/model"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/burningalchemist/sql_exporter/config"
	"github.com/prometheus/client_golang/prometheus"
	dto "github.com/prometheus/client_model/go"

	_ "github.com/prometheus/common/model"
	"google.golang.org/protobuf/proto"
	"k8s.io/klog/v2"

	"net/url"
	"os"
	_ "strconv"
	_ "time"
)

var (
	SvcRegistry        = prometheus.NewRegistry()
	svcMetricLabels    = []string{"job", "target", "collector", "query"}
	scrapeErrorsMetric *prometheus.CounterVec
)
var (
	dbType                = os.Getenv("SQL_EXPORTER_DB_TYPE")
	user                  = url.QueryEscape(os.Getenv("SQL_EXPORTER_USER"))
	password              = url.QueryEscape(os.Getenv("SQL_EXPORTER_PASS"))
	host                  = os.Getenv("SQL_EXPORTER_HOST")
	port                  = os.Getenv("SQL_EXPORTER_PORT")
	dbName                = os.Getenv("SQL_EXPORTER_DB_NAME")
	scrapeTimeoutOffset   = os.Getenv("SCRAPE_TIMEOUT")
	minInterval           = os.Getenv("MIN_INTERVAL")
	maxConnections        = os.Getenv("MAX_CONNECTION")
	maxIdleConnections    = os.Getenv("MAX_IDLE_CONNECTION")
	maxConnectionLifetime = os.Getenv("MAX_CONNECTION_LIFE_TIME")
)

var dsnOverride = flag.String("config.data-source-name", "", "Data source name to override the value in the configuration file with.")

// Exporter is a prometheus.Gatherer that gathers SQL metrics from targets and merges them with the default registry.
type Exporter interface {
	prometheus.Gatherer

	// WithContext returns a (single use) copy of the Exporter, which will use the provided context for Gather() calls.
	WithContext(context.Context) Exporter
	// Config returns the Exporter's underlying Config object.
	Config() *config.Config
	// UpdateTarget updates the targets field
	UpdateTarget([]Target)
	// SetJobFilters sets the jobFilters field
	SetJobFilters([]string)
	// DropErrorMetrics resets the scrape_errors_total metric
	DropErrorMetrics()
}

type exporter struct {
	config     *config.Config
	targets    []Target
	jobFilters []string

	ctx context.Context
}

// NewExporter returns a new Exporter with the provided config.
func NewExporter(configFile string) (Exporter, error) {
	c, err := config.Load(configFile)
	if err != nil {
		return nil, err
	}

	commonDSN := fmt.Sprintf("%v:%v@%v:%v", user, password, host, port)

	switch strings.ToLower(dbType) {
	case "mysql":
		*dsnOverride = fmt.Sprintf("mysql://%s", commonDSN)
	case "gbase8a":
		// 强制修改为MySQL的驱动
		dbType = "mysql"
		cfg := mysql.Config{
			User:                 user,
			Passwd:               password,
			Net:                  "tcp",
			Addr:                 fmt.Sprintf("%v:%v", host, port),
			DBName:               dbName,
			AllowNativePasswords: true,
		}
		*dsnOverride = cfg.FormatDSN()
	case "postgres":
		*dsnOverride = fmt.Sprintf("postgres://%s/%s?sslmode=disable", commonDSN, dbName)
	case "opengauss":
		*dsnOverride = fmt.Sprintf("opengauss://%s/%s?sslmode=disable", commonDSN, dbName)
	case "oracle":
		*dsnOverride = fmt.Sprintf("oracle://%s/%s", commonDSN, dbName)
	case "sqlserver":
		*dsnOverride = fmt.Sprintf("sqlserver://%s?encrypt=disable", commonDSN)
	case "dm": //达梦数据库 版本>=8.1.1.126
		*dsnOverride = fmt.Sprintf("dm://%s", commonDSN)
	default:
		return nil, fmt.Errorf("unsupported database type: %s", dbType)
	}

	// Override the DSN if requested (and in single target mode).
	if *dsnOverride != "" {
		if len(c.Jobs) > 0 {
			return nil, errors.New("the config.data-source-name flag only applies in single target mode")
		}
		c.Target.DSN = config.Secret(*dsnOverride)
	}

	if scrapeTimeoutOffset != "" {
		timeoutOffset, err := model.ParseDuration(scrapeTimeoutOffset)
		if err == nil {
			c.Globals.ScrapeTimeout = timeoutOffset
		} else {
			klog.Errorf("error parse scrapeTimeoutOffset: %v", scrapeTimeoutOffset)
		}
	}

	if minInterval != "" {
		interval, err := model.ParseDuration(minInterval)
		if err == nil {
			c.Globals.MinInterval = interval
		} else {
			klog.Errorf("error parse minInterval: %v", minInterval)
		}
	}

	if maxConnections != "" {
		connection, err := strconv.Atoi(maxConnections)
		if err == nil {
			c.Globals.MaxConns = connection
		} else {
			klog.Errorf("error parse maxConnections: %v", maxConnections)
		}
	}

	if maxIdleConnections != "" {
		idleConnection, err := strconv.Atoi(maxIdleConnections)
		if err == nil {
			c.Globals.MaxIdleConns = idleConnection
		} else {
			klog.Errorf("error parse maxIdleConnections: %v", maxIdleConnections)
		}
	}

	if maxConnectionLifetime != "" {
		connectLife, err := time.ParseDuration(maxConnectionLifetime)
		if err == nil {
			c.Globals.MaxConnLifetime = connectLife
		} else {
			klog.Errorf("error parse maxConnectionLifetime: %v", maxConnectionLifetime)
		}
	}

	var targets []Target
	if c.Target != nil {
		target, err := NewTarget("", c.Target.Name, "", string(c.Target.DSN), c.Target.Collectors(), nil, c.Globals, c.Target.EnablePing)
		if err != nil {
			return nil, err
		}
		targets = []Target{target}
	} else {
		if len(c.Jobs) > (config.MaxInt32 / 3) {
			return nil, errors.New("'jobs' list is too large")
		}
		targets = make([]Target, 0, len(c.Jobs)*3)
		for _, jc := range c.Jobs {
			job, err := NewJob(jc, c.Globals)
			if err != nil {
				return nil, err
			}
			targets = append(targets, job.Targets()...)
		}
	}

	scrapeErrorsMetric = registerScrapeErrorMetric()

	return &exporter{
		config:     c,
		targets:    targets,
		jobFilters: []string{},
		ctx:        context.Background(),
	}, nil
}

func (e *exporter) WithContext(ctx context.Context) Exporter {
	return &exporter{
		config:     e.config,
		targets:    e.targets,
		jobFilters: e.jobFilters,
		ctx:        ctx,
	}
}

// Gather implements prometheus.Gatherer.
func (e *exporter) Gather() ([]*dto.MetricFamily, error) {
	var (
		metricChan = make(chan Metric, capMetricChan)
		errs       prometheus.MultiError
	)

	// Filter out jobs that are not in the jobFilters list
	e.filterTargets(e.jobFilters)

	if len(e.targets) == 0 {
		return nil, errors.New("no targets found")
	}

	var wg sync.WaitGroup
	wg.Add(len(e.targets))
	for _, t := range e.targets {
		go func(target Target) {
			defer wg.Done()
			target.Collect(e.ctx, metricChan)
		}(t)
	}

	// Wait for all collectors to complete, then close the channel.
	go func() {
		wg.Wait()
		close(metricChan)
	}()

	// Drain metricChan in case of premature return.
	defer func() {
		for range metricChan {
		}
	}()

	// Gather.
	dtoMetricFamilies := make(map[string]*dto.MetricFamily, 10)
	for metric := range metricChan {
		dtoMetric := &dto.Metric{}
		if err := metric.Write(dtoMetric); err != nil {
			errs = append(errs, err)
			if err.Context() != "" {
				ctxLabels := parseContextLog(err.Context())
				values := make([]string, len(svcMetricLabels))
				for i, label := range svcMetricLabels {
					values[i] = ctxLabels[label]
				}
				scrapeErrorsMetric.WithLabelValues(values...).Inc()
			}
			continue
		}
		metricDesc := metric.Desc()
		dtoMetricFamily, ok := dtoMetricFamilies[metricDesc.Name()]
		if !ok {
			dtoMetricFamily = &dto.MetricFamily{}
			dtoMetricFamily.Name = proto.String(metricDesc.Name())
			dtoMetricFamily.Help = proto.String(metricDesc.Help())
			switch {
			case dtoMetric.Gauge != nil:
				dtoMetricFamily.Type = dto.MetricType_GAUGE.Enum()
			case dtoMetric.Counter != nil:
				dtoMetricFamily.Type = dto.MetricType_COUNTER.Enum()
			default:
				errs = append(errs, fmt.Errorf("don't know how to handle metric %v", dtoMetric))
				continue
			}
			dtoMetricFamilies[metricDesc.Name()] = dtoMetricFamily
		}
		dtoMetricFamily.Metric = append(dtoMetricFamily.Metric, dtoMetric)
	}

	// No need to sort metric families, prometheus.Gatherers will do that for us when merging.
	result := make([]*dto.MetricFamily, 0, len(dtoMetricFamilies))
	for _, mf := range dtoMetricFamilies {
		result = append(result, mf)
	}
	return result, errs
}

func (e *exporter) filterTargets(jf []string) {
	if len(jf) > 0 {
		var filteredTargets []Target
		for _, target := range e.targets {
			for _, jobFilter := range jf {
				if jobFilter == target.JobGroup() {
					filteredTargets = append(filteredTargets, target)
					break
				}
			}
		}
		if len(filteredTargets) == 0 {
			klog.Errorf("No targets found for job filters. Nothing to scrape.")
		}
		e.targets = filteredTargets
	}
}

// Config implements Exporter.
func (e *exporter) Config() *config.Config {
	return e.config
}

// UpdateTarget implements Exporter.
func (e *exporter) UpdateTarget(target []Target) {
	e.targets = target
}

// SetJobFilters implements Exporter.
func (e *exporter) SetJobFilters(filters []string) {
	e.jobFilters = filters
}

// DropErrorMetrics implements Exporter.
func (e *exporter) DropErrorMetrics() {
	scrapeErrorsMetric.Reset()
	klog.Info("Dropped scrape_errors_total metric")
}

// registerScrapeErrorMetric registers the metrics for the exporter itself.
func registerScrapeErrorMetric() *prometheus.CounterVec {
	scrapeErrors := prometheus.NewCounterVec(prometheus.CounterOpts{
		Name: "scrape_errors_total",
		Help: "Total number of scrape errors per job, target, collector and query",
	}, svcMetricLabels)
	SvcRegistry.MustRegister(scrapeErrors)
	return scrapeErrors
}

// split comma separated list of key=value pairs and return a map of key value pairs
func parseContextLog(list string) map[string]string {
	m := make(map[string]string)
	for _, item := range strings.Split(list, ",") {
		parts := strings.SplitN(item, "=", 2)
		m[parts[0]] = parts[1]
	}
	return m
}

// Leading comma appears when previous parameter is undefined, which is a side-effect of running in single target mode.
// Let's trim to avoid confusions.
func TrimMissingCtx(logContext string) string {
	if strings.HasPrefix(logContext, ",") {
		logContext = strings.TrimLeft(logContext, ", ")
	}
	return logContext
}
