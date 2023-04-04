#!/bin/bash

# 删除监控对象
object=mssql

helm uninstall mssql-2022 --namespace $object

helm uninstall mssql-2019 --namespace $object

helm uninstall mssql-2017 --namespace $object

# Uninstall mssql deployments
for RELEASE in $(helm list -n $object --short)
do
  echo "Uninstalling $RELEASE ..."
  helm uninstall -n $object "$RELEASE"
done
