package sql_exporter

import (
	"strings"
	"testing"
)

func TestBuildDSNSupportsPolarDBPGWithPostgresDriver(t *testing.T) {
	origUser, origPassword, origHost, origPort := rawUser, rawPassword, host, port
	origDBName, origTimeout := dbName, timeout
	defer func() {
		rawUser = origUser
		rawPassword = origPassword
		host = origHost
		port = origPort
		dbName = origDBName
		timeout = origTimeout
	}()

	rawUser = "monitor"
	rawPassword = "Weops123!"
	host = "127.0.0.1"
	port = "5432"
	dbName = "postgres"
	timeout = ""

	driver, dsn, err := buildDSN("polardb_pg")
	if err != nil {
		t.Fatalf("expected polardb_pg dsn support, got error: %v", err)
	}
	if driver != "postgres" {
		t.Fatalf("expected postgres driver for polardb_pg, got %q", driver)
	}
	if !strings.Contains(dsn, "postgres://monitor:Weops123%21@127.0.0.1:5432/postgres") {
		t.Fatalf("expected postgres-compatible polardb pg dsn, got %q", dsn)
	}
	if !strings.Contains(dsn, "sslmode=disable") {
		t.Fatalf("expected sslmode=disable in polardb pg dsn, got %q", dsn)
	}
}

func TestBuildDSNPolarDBPGDefaultsToPostgresDatabase(t *testing.T) {
	origUser, origPassword, origHost, origPort := rawUser, rawPassword, host, port
	origDBName := dbName
	defer func() {
		rawUser = origUser
		rawPassword = origPassword
		host = origHost
		port = origPort
		dbName = origDBName
	}()

	rawUser = "monitor"
	rawPassword = "Weops123!"
	host = "127.0.0.1"
	port = "5432"
	dbName = "" // no explicit db name

	_, dsn, err := buildDSN("polardb_pg")
	if err != nil {
		t.Fatalf("expected polardb_pg dsn support, got error: %v", err)
	}
	// polar_monitor views live in the postgres database, so an empty db name must fall back to it.
	if !strings.Contains(dsn, "@127.0.0.1:5432/postgres") {
		t.Fatalf("expected polardb pg dsn to default to postgres database, got %q", dsn)
	}
}
