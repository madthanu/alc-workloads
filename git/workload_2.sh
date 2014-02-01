#!/bin/bash
trap 'echo Bash error:$0 $1:${LINENO}' ERR
set -e

### INITIALIZING DIRECTORIES FOR COLLECTING TRACES
wd="$(pwd)"
rm -rf "$wd"/tmp
mkdir -p "$wd"/tmp

### INITIALIZING WORKLOAD
rm -rf /mnt/mydisk
mkdir -p /mnt/mydisk
cd /mnt/mydisk
git init .
git config core.fsyncobjectfiles true
dd if=/dev/urandom of=file1 count=5 bs=4196
dd if=/dev/urandom of=file2 count=5 bs=4196

### SNAPSHOTING INITIAL STATE BEFORE WORKLOAD
cp -R /mnt/mydisk "$wd"/tmp/snapshot

### RUNNING WORKLOAD AND COLLECTING TRACE
strace -s 0 -ff -tt -o "$wd"/tmp/strace.out \
	git add .
strace -s 0 -ff -tt -o "$wd"/tmp/strace.out \
	git commit -m "tmp"