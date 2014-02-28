#!/bin/bash
trap 'echo Bash error:$0 $1:${LINENO}' ERR
set -e

function initialize_workload {
	make -s workload
	mkdir -p ./tmp
	rm -rf ./tmp/*
	rm -rf /mnt/mydisk/*
	export workload_dir=/mnt/mydisk
}

function do_workload {
	cp -R /mnt/mydisk ./tmp/snapshot
	mtrace -o ./tmp/strace.out -- ./workload
}

initialize_workload
do_workload
