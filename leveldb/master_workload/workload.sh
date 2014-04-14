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
#	mtrace -o ./tmp/strace.out -- ./workload
	strace -ff -tt -k -o ./tmp/strace.out -- ./workload
	retrieve_symbols.py ./tmp/strace.out
}

initialize_workload
do_workload

sed -i 's:\(open("\./tmp/strace\.out\.mtrace\.byte_dump\):ignore_\1:g' $(ls tmp/strace.out.* | grep -v byte_dump | grep -v mtrace)
