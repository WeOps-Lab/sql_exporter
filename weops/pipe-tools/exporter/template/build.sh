#!/bin/bash

for version in 2022; do
  output_file="standalone_${version}.yaml"
  sed "s/{{VERSION}}/${version}/g" standalone.tpl > ../standalone/${output_file}
done
