#!/bin/bash
kubectl delete -f ./exporter/configMap -n sql-exporter
kubectl delete -f ./exporter/standalone -n sql-exporter
kubectl delete -f ./chaos -n sql-exporter


