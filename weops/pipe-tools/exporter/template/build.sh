#!/bin/bash

for version in 2022 2019 2017; do
  output_file="standalone_${version}.yaml"
  sed "s/{{VERSION}}/${version}/g" standalone.tpl > ../standalone/${output_file}
done

# 定义输出文件的路径和名称
output_file="./mssql_collector_configMap.yml"

# 读取 SQL Collector 配置文件的内容
sql_collector=$(cat ./template/mssql_standard.collector.yml)

# 将 SQL Collector 配置文件中的内容插入到 ConfigMap 文件中
configmap=$(cat ./mssql_collector_configMap.yml | sed "s|{{sqlCollector}}|${sql_collector}|g")

# 将 ConfigMap 内容保存到输出文件中
echo -e $configmap > $output_file