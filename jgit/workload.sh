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
	strace -D -s 0 -ff -tt -o "$wd"/tmp/strace.out \
		$jgit add .
	strace -D -s 0 -ff -tt -o "$wd"/tmp/strace.out \
		echo "Done add"
	strace -D -s 0 -ff -tt -o "$wd"/tmp/strace.out \
		$jgit commit -m "test2"

	cd "$wd"/tmp/
	execved=$(grep execve * | awk -F ':' '{print $1}' | awk -F '.' '{print $3}' | uniq)
	for pid in $execved
	do
		java_found=$(grep execve strace.out.$pid | grep 'java\|echo' | wc -l)
		if [ $java_found -eq 0 ]
		then
			for file in *$pid*
			do
				mv $file ignore_$file
			done
			for file in $(ls | grep 'strace.out' | grep -v 'byte_dump')
			do
				sed -i "s/\([\.:0-9]* \)clone\((.*= $pid\)\$/\1ignore_clone\2/g" $file
			done
		fi
		for file in $(ls | grep 'strace.out' | grep -v 'byte_dump')
		do
			sed -i "s/\([\.:0-9]* \)chmod\((.*\)\$/\1ignore_chmod\2/g" $file
		done
	done
}

initialize_workload
do_workload
