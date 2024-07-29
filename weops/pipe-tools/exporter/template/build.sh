#!/bin/bash

# 测试多对象
for SQL_OBJECT in mysql postgres oracle mssql dm opengauss; do
  output_file="sql_exporter_${SQL_OBJECT}.yaml"
  sed "s/{{SQL_OBJECT}}/${SQL_OBJECT}/g" standalone.tpl > ../standalone/${output_file}
done
