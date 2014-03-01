#!/bin/bash
export workload_dir="$1"
make -s checker
./checker | tee /tmp/short_output_tmp
cat /tmp/short_output_tmp | tr '\n' '.' > /tmp/short_output
