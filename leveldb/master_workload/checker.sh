#!/bin/bash
scratchpad="/dev/shm/madthanu-leveldb"
export workload_dir="$1"
make -s checker
rm -rf $scratchpad/checker_$$
mkdir -p $scratchpad/checker_$$

cp -R "$workload_dir" $scratchpad/checker_$$/workload_dir
repairdb=0 checksums_verify=0 ./checker "$@" 2>&1 | tee -a $scratchpad/checker_$$/long_output > $scratchpad/checker_$$/short_output_tmp
(cat $scratchpad/checker_$$/short_output_tmp | tr '\n' '.'; echo) >> $scratchpad/checker_$$/short_output

rm -rf "$workload_dir"
cp -R $scratchpad/checker_$$/workload_dir "$workload_dir"
repairdb=0 checksums_verify=1 ./checker "$@" 2>&1 | tee -a $scratchpad/checker_$$/long_output > $scratchpad/checker_$$/short_output_tmp
(cat $scratchpad/checker_$$/short_output_tmp | tr '\n' '.'; echo) >> $scratchpad/checker_$$/short_output

rm -rf "$workload_dir"
cp -R $scratchpad/checker_$$/workload_dir "$workload_dir"
repairdb=1 checksums_verify=1 ./checker "$@" 2>&1 | tee -a $scratchpad/checker_$$/long_output > $scratchpad/checker_$$/short_output_tmp
(cat $scratchpad/checker_$$/short_output_tmp | tr '\n' '.'; echo) >> $scratchpad/checker_$$/short_output

rm -rf $scratchpad/checker_$$/workload_dir
cp -R "$workload_dir" $scratchpad/checker_$$/workload_dir
repairdb=0 checksums_verify=0 ./checker "$@" 2>&1 | tee -a $scratchpad/checker_$$/long_output > $scratchpad/checker_$$/short_output_tmp
(cat $scratchpad/checker_$$/short_output_tmp | tr '\n' '.'; echo) >> $scratchpad/checker_$$/short_output

rm -rf "$workload_dir"
cp -R $scratchpad/checker_$$/workload_dir "$workload_dir"
repairdb=0 checksums_verify=1 ./checker "$@" 2>&1 | tee -a $scratchpad/checker_$$/long_output > $scratchpad/checker_$$/short_output_tmp
(cat $scratchpad/checker_$$/short_output_tmp | tr '\n' '.'; echo) >> $scratchpad/checker_$$/short_output

sed -i 's/Fully correct\./C/g' $scratchpad/checker_$$/short_output

cat $scratchpad/checker_$$/short_output | tr '\n' ';'

rm -rf $scratchpad/checker_$$
