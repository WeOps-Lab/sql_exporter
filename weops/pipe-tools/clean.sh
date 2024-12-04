#!/bin/bash
kubectl delete -f ./exporter -n mssql
kubectl delete -f ./exporter/standalone -n mssql

# 卸载监控对象
cd charts
bash helm_uninstall.sh

