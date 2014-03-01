#!/bin/bash
export workload_dir="$1"
make -s checker
./checker "$@" 2>&1 | tee /tmp/short_output_tmp
cat /tmp/short_output_tmp | tr '\n' '.' > /tmp/short_output
