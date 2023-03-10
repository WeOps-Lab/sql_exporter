#!/bin/bash

for version in 2022 2019 2017; do
  output_file="standalone_${version}.yaml"
  sed "s/{{VERSION}}/${version}/g" standalone.tpl > ../standalone/${output_file}
done
