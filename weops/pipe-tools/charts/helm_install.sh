#!/bin/bash

set -euo pipefail

# 部署监控对象
object=mssql

kubectl get namespace "$object" >/dev/null 2>&1 || kubectl create namespace "$object"

install_release() {
  local release=$1
  local values_file=$2
  local chart_dir=$3

  echo ">> deploying ${release}"
  helm upgrade --install "$release" \
    --namespace "$object" \
    --wait \
    --wait-for-jobs \
    --timeout 10m \
    -f "$values_file" \
    "$chart_dir"
}

pids=()
names=()

install_release mssql-2022 ./values/2022_values.yaml ./mssqlserver-2022 &
pids+=("$!")
names+=("mssql-2022")

install_release mssql-2019 ./values/2019_values.yaml ./mssqlserver-2019 &
pids+=("$!")
names+=("mssql-2019")

install_release mssql-2017 ./values/2017_values.yaml ./mssqlserver-2017 &
pids+=("$!")
names+=("mssql-2017")

status=0

for i in "${!pids[@]}"; do
  if wait "${pids[$i]}"; then
    echo ">> ${names[$i]} deployed"
  else
    echo ">> ${names[$i]} failed" >&2
    status=1
  fi
done

exit "$status"
