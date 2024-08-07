#!/bin/bash

# 测试多对象
for SQL_OBJECT in mysql postgres oracle mssql; do
  output_file="sql_exporter_${SQL_OBJECT}.yaml"
  sed "s/{{SQL_OBJECT}}/${SQL_OBJECT}/g" minimal.tpl > ../standalone/${output_file}
done

# 扩展
for SQL_OBJECT in dm opengauss gbase8a; do
  output_file="sql_exporter_${SQL_OBJECT}.yaml"
  sed "s/{{SQL_OBJECT}}/${SQL_OBJECT}/g" plugin.tpl > ../standalone/${output_file}
done