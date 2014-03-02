#!/bin/bash
trap 'echo Bash error:$0 $1:${LINENO}' ERR
set -e

function initialize_workload {
	export workload_dir=$(pwd)/workload_dir
	make -s init
	make -s workload
	mkdir -p ./tmp
	rm -rf ./tmp/*
	mkdir -p $workload_dir
	rm -rf $workload_dir/*
	./init
}

function do_workload {
	cp -R $workload_dir ./tmp/snapshot
	mtrace -o ./tmp/strace.out -- ./workload
}

initialize_workload
do_workload
