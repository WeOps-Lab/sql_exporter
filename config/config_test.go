package config

import (
	"reflect"
	"testing"
)

func TestResolveCollectorRefs(t *testing.T) {
	colls := map[string]*CollectorConfig{
		"a":  {Name: "a"},
		"b":  {Name: "b"},
		"c":  {Name: "b"},
		"aa": {Name: "aa"},
	}

	t.Run("NoGlobbing", func(t *testing.T) {
		crefs := []string{
			"a",
			"b",
		}
		cs, err := resolveCollectorRefs(crefs, colls, "target")
		if err != nil {
			t.Fatalf("expected no error but got: %v", err)
		}
		if len(cs) != 2 {
			t.Fatalf("expected len(cs)=2 but got len(cs)=%d", len(cs))
		}
		expected := []*CollectorConfig{
			colls["a"],
			colls["b"],
		}
		if !reflect.DeepEqual(cs, expected) {
			t.Fatalf("expected cs=%v but got cs=%v", expected, cs)
		}
	})

	t.Run("Globbing", func(t *testing.T) {
		crefs := []string{
			"a*",
			"b",
		}
		cs, err := resolveCollectorRefs(crefs, colls, "target")
		if err != nil {
			t.Fatalf("expected no error but got: %v", err)
		}
		if len(cs) != 3 {
			t.Fatalf("expected len(cs)=3 but got len(cs)=%d", len(cs))
		}
		expected1 := []*CollectorConfig{
			colls["a"],
			colls["aa"],
			colls["b"],
		}
		expected2 := []*CollectorConfig{ // filepath.Match() is non-deterministic
			colls["aa"],
			colls["a"],
			colls["b"],
		}
		if !reflect.DeepEqual(cs, expected1) && !reflect.DeepEqual(cs, expected2) {
			t.Fatalf("expected cs=%v or cs=%v but got cs=%v", expected1, expected2, cs)
		}
	})

	t.Run("NoCollectorRefs", func(t *testing.T) {
		crefs := []string{}
		cs, err := resolveCollectorRefs(crefs, colls, "target")
		if err != nil {
			t.Fatalf("expected no error but got: %v", err)
		}
		if len(cs) != 0 {
			t.Fatalf("expected len(cs)=0 but got len(cs)=%d", len(cs))
		}
	})

	t.Run("UnknownCollector", func(t *testing.T) {
		crefs := []string{
			"a",
			"x",
		}
		_, err := resolveCollectorRefs(crefs, colls, "target")
		if err == nil {
			t.Fatalf("expected error but got none")
		}
		// TODO: Code should use error types and check with 'errors.Is(err1, err2)'.
		expected := "unknown collector \"x\" referenced in target"
		if err.Error() != expected {
			t.Fatalf("expected err=%q but got err=%q", expected, err.Error())
		}
	})
}

func TestLoadPolarDBPGCollectorFile(t *testing.T) {
	c, err := Load("../polardb_pg.collector.yml")
	if err != nil {
		t.Fatalf("expected polardb pg collector to load, got error: %v", err)
	}
	if got := c.GetCollectorDBType(); got != "polardb_pg" {
		t.Fatalf("expected collector db type polardb_pg, got %q", got)
	}
	if len(c.Collectors) != 1 {
		t.Fatalf("expected one collector, got %d", len(c.Collectors))
	}
	if got := c.Collectors[0].Name; got != "polardb_pg_sql" {
		t.Fatalf("expected collector name polardb_pg_sql, got %q", got)
	}
	if len(c.Collectors[0].Metrics) == 0 {
		t.Fatal("expected polardb pg collector metrics")
	}
}
