#!/bin/bash
### All initialization stuff
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

### Actual program checker
rm -rf /mnt/mydisk
cp -R "$replayed_snapshot" /mnt/mydisk
rm -rf /tmp/scratchpad
cp -R "$replayed_snapshot" /tmp/scratchpad
echo "not done" > /tmp/short_output
cd /mnt/mydisk


echo 0 > /tmp/lock_found

function git {
	/root/application_fs_bugs/alc-workloads/jgit/org.eclipse.jgit.pgm-3.2.0.201312181205-r.sh "$@"
}

function refs_log_check {
	function matches {
		str1="$1"
		str2="$2"
		ret=$(diff <(echo "$str1" | sed 's/[ \t]//g' | grep -v '^$') <(echo "$str2" | sed 's/[ \t]//g' | grep -v '^$') | wc -l)
		if [ $ret -eq 0 ]
		then
			echo 1
		else
			echo 0
		fi
	}
	o1=$(git show-ref 2>&1)
	o1_c1='34cbd4e9e9e252c2feac87c3d36edd7967b9c6be	HEAD
		34cbd4e9e9e252c2feac87c3d36edd7967b9c6be	refs/heads/master'
	o1_c2='e318e4aa5c5b555f0fceb8e315991087e1ff27aa	HEAD
		e318e4aa5c5b555f0fceb8e315991087e1ff27aa	refs/heads/master'

	o2=$(git reflog 2>&1)
	o2_c1='34cbd4e HEAD@{0}: commit: test2
		e318e4a HEAD@{1}: commit (initial): test1'
	o2_c2='e318e4a HEAD@{0}: commit (initial): test1'

	o3=$(git log 2>&1)
	o3_c1='commit 34cbd4e9e9e252c2feac87c3d36edd7967b9c6be
		Author: root <root@adsl-21.cs.wisc.edu>
		Date:   Mon Jan 27 20:20:49 2014 -0600
		    test2
		commit e318e4aa5c5b555f0fceb8e315991087e1ff27aa
		Author: root <root@adsl-21.cs.wisc.edu>
		Date:   Mon Jan 27 20:20:46 2014 -0600
		    test1'
	o3_c2='commit e318e4aa5c5b555f0fceb8e315991087e1ff27aa
		Author: root <root@adsl-21.cs.wisc.edu>
		Date:   Mon Jan 27 20:20:46 2014 -0600
		    test1'
	if [ $(matches "$o1" "$o1_c1") -eq 0 ] && [ $(matches "$o1" "$o1_c2") -eq 0 ]
	then
		echo "insane o1"
		return
	fi
	if [ $(matches "$o2" "$o2_c1") -eq 0 ] && [ $(matches "$o2" "$o2_c2") -eq 0 ]
	then
		echo "insane o2"
		return
	fi
	if [ $(matches "$o3" "$o3_c1") -eq 0 ] && [ $(matches "$o3" "$o3_c2") -eq 0 ]
	then
		echo "insane o3"
		return
	fi
	o1_commit=$(echo "$o1" | awk '{print substr($1, 0, 7)}' | head -1)
	o2_commit=$(echo "$o2" | awk '{print $1}' | head -1)
	o3_commit=$(echo "$o3" | head -1 | awk '{print substr($2, 0, 7)}')
	if [ $o1_commit == $o2_commit ] && [ $o2_commit == $o3_commit ]
	then
		echo "consistent, $o1_commit"
	else
		echo "inconsistent, $o1_commit, $o2_commit, $o3_commit"
	fi
}

function status_check {
	last_commit="$1"

	o_status=$(git status 2>&1)
	if [ "$last_commit" == "34cbd4e" ]
	then
		correct_output='# On branch master'
		o_consistent=$(diff <(echo "$o_status" | sed 's/[ \t]//g' | grep -v '^#$') <(echo "$correct_output" | sed 's/[ \t]//g' | grep -v '^#$') | wc -l)
		if [ $o_consistent -ne 0 ]
		then
			echo "inconsistent"
			return
		fi
		echo "consistent"
		return
	fi


	o_file3_tracked='# On branch master
			# Changes to be committed:
			# 
			#	new file:   file3
			# Untracked files:
			# 
			#	file4'
	o_both_tracked='# On branch master
			# Changes to be committed:
			# 
			#	new file:   file3
			#	new file:   file4'
	o_both_untracked='# On branch master
			# Untracked files:
			# 
			# 	file3
			# 	file4'
	o_file3_tracked_match=$(diff <(echo "$o_status" | sed 's/[ \t]//g' | grep -v '^#$') <(echo "$o_file3_tracked" | sed 's/[ \t]//g' | grep -v '^#$') | wc -l)
	o_both_tracked_match=$(diff <(echo "$o_status" | sed 's/[ \t]//g' | grep -v '^#$') <(echo "$o_both_tracked" | sed 's/[ \t]//g' | grep -v '^#$') | wc -l)
	o_both_untracked_match=$(diff <(echo "$o_status" | sed 's/[ \t]//g' | grep -v '^#$') <(echo "$o_both_untracked" | sed 's/[ \t]//g' | grep -v '^#$') | wc -l)
	
	if [ $o_file3_tracked_match -eq 0 ]
	then
		echo "consistent, file3 tracked"
		return
	fi

	if [ $o_both_tracked_match -eq 0 ]
	then
		echo "consistent, both tracked"
		return
	fi

	if [ $o_both_untracked_match -eq 0 ]
	then
		echo "consistent, both untracked"
		return
	fi

	echo "inconsistent"
}

function rm_add_commit_check {
	current_commit="$1"
	o_rm=$(git rm file1 file2 2>&1) || true
	lock_exists_output="Caused by: org.eclipse.jgit.errors.LockFailedException: Cannot lock /tmp/replayed_snapshot/.git/index"
	o_lock_exists=$(grep "$lock_exists_output" <(echo "$o_rm") | wc -l)
	if [ -f /mnt/mydisk/.git/index.lock ]
	then
		if [ $o_lock_exists -ne 0 ]
		then
			echo "inconsistent, no-lock-warning git-rm"
			return
		else
			echo 1 > /tmp/lock_found
			echo "consistentL"
			return
		fi
	fi

	o_consistent=$(echo "$o_rm" | grep -v '^$' | wc -l)
	if [ $o_consistent -ne 0 ]
	then
		echo "$o_rm"
		echo "inconsistent, git-rm"
		return
	fi

	echo hello > file5
	o_add=$(git add . 2>&1) || true
	o_consistent=$(echo "$o_add" | grep -v '^$' | wc -l)
	if [ $o_consistent -ne 0 ]
	then
		echo "inconsistent, git-add"
		return
	fi

	o_commit=$(git commit -m "test3" 2>&1) || true
	lock_exists_output="Caused by: org.eclipse.jgit.errors.LockFailedException: Cannot lock /tmp/replayed_snapshot/.git/refs/heads/master"
	o_lock_exists=$(grep "$lock_exists_output" <(echo "$o_commit") | wc -l)
	if [ -f /mnt/mydisk/.git/refs/heads/master.lock ]
	then
		if [ $o_lock_exists -eq 0 ]
		then
			echo "$o_commit"
			echo "inconsistent, no-lock-warning"
			return
		fi
	fi
	if [ $o_lock_exists -eq 1 ]
	then
		# lock actually does exist
		echo 1 > /tmp/lock_found
		echo "consistentL"
		return;
	fi
	o_correct_part='[master ........................................] test3'
	o_consistent=$(echo "$o_commit" | grep -v "[master ........................................] test3" | grep -v '^$' | wc -l)
	if [ $o_consistent -ne 0 ]
	then
		echo "$o_commit"
		echo "inconsistent, git-commit"
		return
	fi
	echo "consistent"
}

function post_checks {
	function check_data {
		file="$1"
		msg="$2"
		o_correct=$(diff /mnt/mydisk/$file /tmp/scratchpad/$file | wc -l)
		if [ $o_correct -ne 0 ]
		then
			echo "inconsistent data, $file, $msg"
		fi
	}

	last_commit="$1"

	ls_output=$(ls -o | awk '{print $4 " " $8}' | grep -v '^ $')
	correct_output='20960 file3
			20960 file4
			6 file5'
	o_correct=$(diff <(echo "$correct_output" | sed 's/[ \t]//g') <(echo "$ls_output" | sed 's/[ \t]//g') | wc -l)
	if [ $o_correct -ne 0 ]
	then
		echo "inconsistent directory after all commit operations"
		return
	fi
	check_data file3 "after all commit operations"
	check_data file4 "after all commit operations"

	o_checkout=$(git checkout ed47257 2>&1)
	correct_output='Note: checking out '"'"'ed47257'"'"'.
			You are in '"'"'detached HEAD'"'"' state. You can look around, make experimental
			changes and commit them, and you can discard any commits you make in this
			state without impacting any branches by performing another checkout.
			If you want to create a new branch to retain commits you create, you may
			do so (now or later) by using -b with the checkout command again. Example:
			git checkout -b new_branch_name
			HEAD is now at ed47257... test1'
	o_correct=$(diff <(echo "$correct_output" | sed 's/[ \t]//g' | grep -v '^$') <(echo "$o_checkout" | sed 's/[ \t]//g' | grep -v '^$') | wc -l)
	if [ $o_correct -ne 0 ]
	then
		echo "inconsistent checkout, first commit"
		return
	fi

	ls_output=$(ls -o | awk '{print $4 " " $8}' | grep -v '^ $')
	correct_output='20960 file1
			20960 file2'
	o_correct=$(diff <(echo "$correct_output" | sed 's/[ \t]//g') <(echo "$ls_output" | sed 's/[ \t]//g') | wc -l)
	if [ $o_correct -ne 0 ]
	then
		echo "inconsistent directory, first commit"
		return
	fi
	check_data file1 "after checking out first commit"
	check_data file2 "after checking out first commit"

	o_checkout=$(git checkout master 2>&1)
	correct_output='Previous HEAD position was ed47257... test1
			Switched to branch '"'"'master'"'"''
	o_correct=$(diff <(echo "$correct_output" | sed 's/[ \t]//g' | grep -v '^$') <(echo "$o_checkout" | sed 's/[ \t]//g' | grep -v '^$') | wc -l)
	if [ $o_correct -ne 0 ]
	then
		echo "inconsistent, middle checkout"
		return
	fi

	if [ "$last_commit" != "34cbd4e" ]
	then
		echo "consistent directory"
		return
	fi

	o_checkout=$(git checkout 34cbd4e 2>&1)
	correct_output='Note: checking out '"'"'34cbd4e'"'"'.
			You are in '"'"'detached HEAD'"'"' state. You can look around, make experimental
			changes and commit them, and you can discard any commits you make in this
			state without impacting any branches by performing another checkout.
			If you want to create a new branch to retain commits you create, you may
			do so (now or later) by using -b with the checkout command again. Example:
			git checkout -b new_branch_name
			HEAD is now at b76cefa... test2'
	o_correct=$(diff <(echo "$correct_output" | sed 's/[ \t]//g' | grep -v '^$') <(echo "$o_checkout" | sed 's/[ \t]//g' | grep -v '^$') | wc -l)
	if [ $o_correct -ne 0 ]
	then
		echo "inconsistent checkout, final commit"
		return
	fi

	ls_output=$(ls -o | awk '{print $4 " " $8}' | grep -v '^ $')
	correct_output='20960 file1
			20960 file2
			20960 file3
			20960 file4'
	o_correct=$(diff <(echo "$correct_output" | sed 's/[ \t]//g') <(echo "$ls_output" | sed 's/[ \t]//g') | wc -l)
	if [ $o_correct -ne 0 ]
	then
		echo "inconsistent directory, final commit"
		return
	fi
	check_data file1 "after checking out final commit"
	check_data file2 "after checking out final commit"
	check_data file3 "after checking out final commit"
	check_data file4 "after checking out final commit"
	echo "consistent directory"
}

refs_log_check_output=$(refs_log_check)
echo "refs_log_check: $refs_log_check_output"
short_summary=$(echo $refs_log_check_output | awk -F ',' '{print $1}')
last_commit=$(echo $refs_log_check_output | awk '{print $2}')

status_check_output=$(status_check $last_commit)
echo "status_check: $status_check_output"
short_summary="$short_summary; $status_check_output"

rm_add_commit_check_output=$(rm_add_commit_check $last_commit)
echo "rm_add_commit_check: $rm_add_commit_check_output"
short_summary="$short_summary; $rm_add_commit_check_output"

exit

post_checks_output=$(post_checks $last_commit)
echo "post_checks: $post_checks_output"
short_summary="$short_summary; $post_checks_output"

echo "lock_found: $(cat /tmp/lock_found)"
if [ $(cat /tmp/lock_found) -eq 1 ]
then
	short_summary="$short_summary; L"
fi

echo "$short_summary" | sed 's/consistent/C/g' | sed 's/dangling/D/g' | sed 's/directory/dir/g' | sed 's/both tracked/T/g' | sed 's/both untracked/U/g' > /tmp/short_output

