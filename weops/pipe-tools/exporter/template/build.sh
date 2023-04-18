#!/bin/bash

for SQL_OBJECT in mysql postgres; do
  output_file="sql_exporter_${SQL_OBJECT}.yaml"
  sed "s/{{SQL_OBJECT}}/${SQL_OBJECT}/g" standalone.tpl > ../standalone/${output_file}
done
