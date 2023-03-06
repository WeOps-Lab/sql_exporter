#!/bin/bash

# 部署监控对象
object_versions=("2022", "2019", "2017")
object=mssql

for version in "${object_versions[@]}"; do
    helm install mssql-$version --namespace $object -f ./values/${version}_values.yaml \
    --set deployment.labels.object_version="$version" \
    ./mssqlserver-2022
done
