//go:build ignore

package main

import (
	"fmt"
	"os"

	. "github.com/dave/jennifer/jen"
)

const (
	packageName string = "sql_exporter"
	filename    string = "drivers.go"
)

var driverList = map[string][]string{
	"minimal": {
		"github.com/go-sql-driver/mysql",
		"github.com/lib/pq",
		"github.com/microsoft/go-mssqldb/azuread",
		"github.com/sijms/go-ora/v2",
		"gitee.com/chunanyong/dm",
	},
	"extra": {
		"github.com/ClickHouse/clickhouse-go/v2",
		"github.com/jackc/pgx/v5/stdlib",
		"github.com/snowflakedb/gosnowflake",
		"github.com/vertica/vertica-sql-go",
	},
	"custom": {
		"github.com/mithrandie/csvq-driver",
	},
}

func main() {
	var enabledDrivers []string

	args := os.Args[2:]

	if args[0] == "all" {
		for k := range driverList {
			if k != "custom" {
				enabledDrivers = append(enabledDrivers, driverList[k]...)
			}
		}
	} else {
		var ok bool
		enabledDrivers, ok = driverList[args[0]]
		if !ok {
			fmt.Printf("Nonexistent key. Do nothing.\n")
			os.Exit(0)
		}
	}

	f := NewFile(packageName)
	f.HeaderComment("// Code generated by \"drivers_gen.go\"")
	f.Anon(enabledDrivers...)
	fmt.Println("Following drivers are to be added:")

	for _, v := range enabledDrivers {
		fmt.Printf("> %s\n", v)
	}

	fmt.Printf("Save to '%s'\n", filename)
	if err := f.Save(filename); err != nil {
		fmt.Println(err.Error())
		os.Exit(1)
	}
}
