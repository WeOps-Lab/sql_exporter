package sql_exporter

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"github.com/burningalchemist/sql_exporter/config"
	"github.com/prometheus/client_golang/prometheus"
	dto "github.com/prometheus/client_model/go"
	"github.com/prometheus/common/model"
	"google.golang.org/protobuf/proto"
	"k8s.io/klog/v2"
	"os"
	"strconv"
	"strings"
	"sync"
	"time"
)

var (
	dbType                = os.Getenv("SQL_EXPORTER_DB_TYPE")
	user                  = os.Getenv("SQL_EXPORTER_USER")
	password              = os.Getenv("SQL_EXPORTER_PASS")
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
	UpdateTarget([]Target)
}

type exporter struct {
	config  *config.Config
	targets []Target

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
		*dsnOverride = fmt.Sprintf("mysql://%v", commonDSN)
	case "postgres":
		*dsnOverride = fmt.Sprintf("postgres://%v/%v?sslmode=disable", commonDSN, dbName)
	case "oracle":
		*dsnOverride = fmt.Sprintf("oracle://%v/%v", commonDSN, dbName)
	case "sqlserver":
		*dsnOverride = fmt.Sprintf("sqlserver://%v", commonDSN)
	}

	// Override the DSN if requested (and in single target mode).
	if *dsnOverride != "" {
		if len(c.Jobs) > 0 {
			return nil, fmt.Errorf("the config.data-source-name flag (value %q) only applies in single target mode", *dsnOverride)
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
		target, err := NewTarget("", "", string(c.Target.DSN), c.Target.Collectors(), nil, c.Globals)
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

	return &exporter{
		config:  c,
		targets: targets,
		ctx:     context.Background(),
	}, nil
}

func (e *exporter) WithContext(ctx context.Context) Exporter {
	return &exporter{
		config:  e.config,
		targets: e.targets,
		ctx:     ctx,
	}
}

// Gather implements prometheus.Gatherer.
func (e *exporter) Gather() ([]*dto.MetricFamily, error) {
	var (
		metricChan = make(chan Metric, capMetricChan)
		errs       prometheus.MultiError
	)

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

// Config implements Exporter.
func (e *exporter) Config() *config.Config {
	return e.config
}

func (e *exporter) UpdateTarget(target []Target) {
	e.targets = target
}
