#!/bin/bash

# 部署监控对象
helm install mssql2022 --namespace mssql \
--set acceptEula.value=Y \
--set edition.value=Developer \
--set sapassword='Weops123!' \
--set persistence.enabled=false \
--set deployment.labels.object='mssql' \
--set resources.limits.memory='3Gi' \
./mssqlserver-2022