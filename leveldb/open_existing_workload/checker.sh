#!/bin/bash
export workload_dir="$1"
make -s checker
rm -rf /tmp/checker_$$
mkdir -p /tmp/checker_$$

cp -R "$workload_dir" /tmp/checker_$$/workload_dir
repairdb=0 checksums_verify=0 ./checker "$@" 2>&1 | tee -a /tmp/checker_$$/long_output > /tmp/checker_$$/short_output_tmp
(cat /tmp/checker_$$/short_output_tmp | tr '\n' '.'; echo) >> /tmp/checker_$$/short_output

rm -rf "$workload_dir"
cp -R /tmp/checker_$$/workload_dir "$workload_dir"
repairdb=0 checksums_verify=1 ./checker "$@" 2>&1 | tee -a /tmp/checker_$$/long_output > /tmp/checker_$$/short_output_tmp
(cat /tmp/checker_$$/short_output_tmp | tr '\n' '.'; echo) >> /tmp/checker_$$/short_output

rm -rf "$workload_dir"
cp -R /tmp/checker_$$/workload_dir "$workload_dir"
repairdb=1 checksums_verify=0 ./checker "$@" 2>&1 | tee -a /tmp/checker_$$/long_output > /tmp/checker_$$/short_output_tmp
(cat /tmp/checker_$$/short_output_tmp | tr '\n' '.'; echo) >> /tmp/checker_$$/short_output

rm -rf /tmp/checker_$$/workload_dir
cp -R "$workload_dir" /tmp/checker_$$/workload_dir
repairdb=0 checksums_verify=0 ./checker "$@" 2>&1 | tee -a /tmp/checker_$$/long_output > /tmp/checker_$$/short_output_tmp
(cat /tmp/checker_$$/short_output_tmp | tr '\n' '.'; echo) >> /tmp/checker_$$/short_output

rm -rf "$workload_dir"
cp -R /tmp/checker_$$/workload_dir "$workload_dir"
repairdb=0 checksums_verify=1 ./checker "$@" 2>&1 | tee -a /tmp/checker_$$/long_output > /tmp/checker_$$/short_output_tmp
(cat /tmp/checker_$$/short_output_tmp | tr '\n' '.'; echo) >> /tmp/checker_$$/short_output

sed -i 's/Fully correct\./C/g' /tmp/checker_$$/short_output

cat /tmp/checker_$$/short_output | tr '\n' ';'

rm -rf /tmp/checker_$$
