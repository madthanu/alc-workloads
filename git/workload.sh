#!/bin/bash
trap 'echo Bash error:$0 $1:${LINENO}' ERR
set -e
alias git='/root/application_fs_bugs/git/installation/bin/git'

wd="$(pwd)"

function initialize_workload {
	rm -rf "$wd"/tmp
	mkdir -p "$wd"/tmp
	rm -rf "$wd"/workload_dir
	mkdir -p "$wd"/workload_dir
	cd "$wd"/workload_dir
	git init .
	git config core.fsyncobjectfiles true
	git config user.name john
	git config user.email smith
	dd if=/dev/urandom of=file1 count=5 bs=4192
	dd if=/dev/urandom of=file2 count=5 bs=4192
	git add .
	git commit -m "test1"
	dd if=/dev/urandom of=file3 count=5 bs=4192
	dd if=/dev/urandom of=file4 count=5 bs=4192
}

function do_workload {
	cp -R "$wd"/workload_dir "$wd"/tmp/snapshot
	strace -s 0 -ff -tt -o "$wd"/tmp/strace.out \
		git add .
	strace -s 0 -ff -tt -o "$wd"/tmp/strace.out \
		git commit -m "test2"
	git log | grep '^commit' | awk '{print $2}' > "$wd"/tmp/checker_params
}

initialize_workload
do_workload
