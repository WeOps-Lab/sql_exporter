#!/bin/bash

# 部署监控对象
object=mssql

helm install mssql-2022 --namespace $object -f ./values/2022_values.yaml \
--set pod.labels.object_version="2022" \
./mssqlserver-2022

helm install mssql-2019 --namespace $object -f ./values/2019_values.yaml \
--set pod.labels.object_version="2019" \
./mssqlserver-2019

helm install mssql-2017 --namespace $object -f ./values/2017_values.yaml \
--set pod.labels.object_version="2017" \
./mssqlserver-2019