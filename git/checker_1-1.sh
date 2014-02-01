#!/bin/bash

### General initialization stuff
trap 'echo Bash error:$0 $1:${LINENO}' ERR
set -e

if [ $# -ne 1 ]
then
	echo 'Error: Number of arguments to checker should be 1'
fi

if [ "${1:0:1}" == "/" ]
then
	replayed_snapshot="$1"
else
	replayed_snapshot="$(pwd)/$1"
fi


### Initializing directories
rm -rf /mnt/mydisk
cp -R "$replayed_snapshot" /mnt/mydisk
cd /mnt/mydisk

### Actual checks
echo "incorrect" > /tmp/short_output
full_output=$(git status)
echo "$full_output"
if [ $( echo "$full_output" | grep -v '^#' | grep -v '^nothing added to commit' | wc -l ) -eq 0 ]
then
	echo correct > /tmp/short_output
fi

git commit -m "tmp"

