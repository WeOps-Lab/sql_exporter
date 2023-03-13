#!/bin/bash

# 部署监控对象
object=mssql

helm install mssql-2022 --namespace $object -f ./values/2022_values.yaml ./mssqlserver-2022
kubectl patch -n $object service mssqlserver-2022 -p '{"spec": {"ports": [{"nodePort": 1433}]}}'

helm install mssql-2019 --namespace $object -f ./values/2019_values.yaml ./mssqlserver-2019
kubectl patch -n $object service mssqlserver-2019 -p '{"spec": {"ports": [{"nodePort": 1434}]}}'

helm install mssql-2017 --namespace $object -f ./values/2017_values.yaml ./mssqlserver-2017
kubectl patch -n $object service mssql-2017-mssql-linux -p '{"spec": {"ports": [{"nodePort": 1435}]}}'
