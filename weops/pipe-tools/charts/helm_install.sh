#!/bin/bash

# 部署监控对象
object=mssql

helm install mssql-2022 --namespace $object -f ./values/2022_values.yaml ./mssqlserver-2022

helm install mssql-2019 --namespace $object -f ./values/2019_values.yaml ./mssqlserver-2019

helm install mssql-2017 --namespace $object -f ./values/2017_values.yaml ./mssqlserver-2017