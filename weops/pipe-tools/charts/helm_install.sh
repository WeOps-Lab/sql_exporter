#!/bin/bash

# 部署监控对象
object_versions=("2022", "2019", "2017")
object=mssql

for version in "${object_versions[@]}"; do
    version_suffix="$version"

    helm install mssql-$version_suffix --namespace $object -f ./values/standalone_values.yaml \
    --set image.tag="$version-latest" \
    --set deployment.labels.object_version=$version_suffix \
    ./mssqlserver-2022
done
