#!/bin/bash

# 部署监控对象
object_versions=("2022", "2019", "2017")
object=mssql

helm install mssql-"$version" --namespace $object -f ./values/2022_values.yaml \
--set pod.labels.object_version="$version" \
./mssqlserver

helm install mssql-"$version" --namespace $object -f ./values/2019_values.yaml \
--set pod.labels.object_version="$version" \
./mssqlserver

helm install mssql-"$version" --namespace $object -f ./values/2017_values.yaml \
--set pod.labels.object_version="$version" \
./mssqlserver