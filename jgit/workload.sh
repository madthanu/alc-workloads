#!/bin/bash
trap 'echo Bash error:$0 $1:${LINENO}' ERR
set -e
jgit="/root/application_fs_bugs/alc-workloads/jgit/org.eclipse.jgit.pgm-3.2.0.201312181205-r.sh"
wd="$(pwd)"

function initialize_workload {
	rm -rf "$wd"/tmp
	mkdir -p "$wd"/tmp
	rm -rf /mnt/mydisk/*
	rm -rf /mnt/mydisk/.git
	cd /mnt/mydisk
	$jgit init
	dd if=/dev/urandom of=file1 count=5 bs=4192
	dd if=/dev/urandom of=file2 count=5 bs=4192
	$jgit add .
	$jgit commit -m "test1"
	dd if=/dev/urandom of=file3 count=5 bs=4192
	dd if=/dev/urandom of=file4 count=5 bs=4192
}

function do_workload {
	cp -R /mnt/mydisk "$wd"/tmp/snapshot
	strace -D -s 10 -ff -tt -o "$wd"/tmp/strace.out \
		$jgit add .
	strace -D -s 10 -ff -tt -o "$wd"/tmp/strace.out \
		$jgit commit -m "test2"

	execved=$(grep execve "$wd"/tmp/* | awk -F ':' '{print $1}' | awk -F '.' '{print $3}' | uniq)
	for pid in $execved
	do
		java_found=$(grep execve "$wd"/tmp/strace.out.$pid | grep java | wc -l)
		if [ $java_found -eq 0 ]
		then
			rm "$wd"/tmp/*$pid*
		fi
	done
}

initialize_workload
do_workload
