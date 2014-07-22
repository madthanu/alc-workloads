#!/bin/bash
### All initialization stuff
trap 'echo Bash error:$0 $1:${LINENO}' ERR
set -e

if [ "${1:0:1}" == "/" ]
then
	replayed_snapshot="$1"
else
	replayed_snapshot="$(pwd)/$1"
fi

stdout="$2"
scratchpad='/dev/shm/madthanu-git'

mkdir -p $scratchpad/gchecker_$$
echo TERMINATED > $scratchpad/gchecker_$$/short_output

### Initialize workload parameters
second_commit_long=$(head -1 tmp/checker_params)
first_commit_long=$(tail -1 tmp/checker_params)
second_commit_short=$(head -1 tmp/checker_params | awk '{print substr($1, 0, 7)'})
first_commit_short=$(tail -1 tmp/checker_params | awk '{print substr($1, 0, 7)'})
git_author='john <smith>'

if [ $first_commit_long == '' ] || [ $second_commit_long == '' ]
then
	echo "ERROR: Checker parameters not initialized by workload script."
	echo "ERROR: Checker parameters not initialized by workload script." > $scratchpad/gchecker_$$/short_output
	exit 1
fi

### Initializing directories
#rm -rf $scratchpad/gchecker_$$/scratchpad
#cp -R "$replayed_snapshot" $scratchpad/gchecker_$$/scratchpad
echo "not done" > $scratchpad/gchecker_$$/short_output
cd $replayed_snapshot

### Variable to track whether a lock existed in this crash scenario
echo 0 > $scratchpad/gchecker_$$/lock_found
echo 0 > $scratchpad/gchecker_$$/timed_out

function git {
	#timeout -k 1 2 git "$@"
	timeout 3 git "$@"
	if [ $? -eq 124 ]
	then
		echo "timeout"
		echo 1 > $scratchpad/gchecker_$$/timed_out
	fi
}

### Actual checkers
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
	o1_c1="$second_commit_long refs/heads/master"
	o1_c2="$first_commit_long refs/heads/master"

	o2=$(git show-ref -h HEAD 2>&1)
	o2_c1="$second_commit_long HEAD"
	o2_c2="$first_commit_long HEAD"

	o3=$(git reflog 2>&1)
	o3_c1="$second_commit_short HEAD@{0}: commit: test2
		$first_commit_short HEAD@{1}: commit (initial): test1"
	o3_c2="$first_commit_short HEAD@{0}: commit (initial): test1"

	o4=$(git log 2>&1 | grep -v Date)
	o4_c1="commit $second_commit_long
		Author: $git_author
		test2
		commit $first_commit_long
		Author: $git_author
		test1"
	o4_c2="commit $first_commit_long
		Author: $git_author
		test1"
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
	if [ $(matches "$o4" "$o4_c1") -eq 0 ] && [ $(matches "$o4" "$o4_c2") -eq 0 ]
	then
		echo "$o4"
		echo "$o4_c1"
		echo "insane o4"
		return
	fi
	o1_commit=$(echo "$o1" | awk '{print substr($1, 0, 7)}' | head -1)
	o2_commit=$(echo "$o2" | awk '{print substr($1, 0, 7)}' | head -1)
	o3_commit=$(echo "$o3" | awk '{print $1}' | head -1)
	o4_commit=$(echo "$o4" | head -1 | awk '{print substr($2, 0, 7)}')
	if [ $o1_commit == $o2_commit ] && [ $o2_commit == $o3_commit ] && [ $o3_commit == $o4_commit ]
	then
		echo "consistent, $o1_commit"
	else
		echo "inconsistent, $o1_commit, $o2_commit, $o3_commit, $o4_commit"
	fi
}

function status_check {
	last_commit="$1"

	o_status=$(git status 2>&1)
	if [ "$last_commit" == "$second_commit_short" ]
	then
		correct_output='# On branch master
				nothing to commit (working directory clean)'
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
			#   (use "git reset HEAD <file>..." to unstage)
			#	new file:   file3
			# Untracked files:
			#   (use "git add <file>..." to include in what will be committed)
			#	file4'
	o_both_tracked='# On branch master
			# Changes to be committed:
			#   (use "git reset HEAD <file>..." to unstage)
			#	new file:   file3
			#	new file:   file4'
	o_both_untracked='# On branch master
			# Untracked files:
			#   (use "git add <file>..." to include in what will be committed)
			#	file3
			#	file4
			nothing added to commit but untracked files present (use "git add" to track)'
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

function fsck_check {
	o=$(git fsck 2>&1)
	if [ $(echo "$o" | grep -v '^$' | wc -l) -eq 0 ]
	then
		echo "consistent"
	else
		echo "$o"
	fi
}

function rm_add_commit_check {
	current_commit="$1"
	o_rm=$(git rm file1 file2 2>&1) || true
	lock_exists_output='''fatal: Unable to create '"'$replayed_snapshot"'/.git/index.lock'"'"': File exists.
				If no other git process is currently running, this probably means a
				git process crashed in this repository earlier. Make sure no other git
				process is running and remove the file manually to continue.'''
	o_lock_exists=$(diff <(echo "$o_rm" | sed 's/[ \t]//g' | grep -v '^$') <(echo "$lock_exists_output" | sed 's/[ \t]//g' | grep -v '^$') | wc -l)
	if [ -f $replayed_snapshot/.git/index.lock ]
	then
		if [ $o_lock_exists -ne 0 ]
		then
			echo "inconsistent, no-lock-warning git-rm"
			return
		else
			echo 1 > $scratchpad/gchecker_$$/lock_found
			rm -f $replayed_snapshot/.git/index.lock
			o_rm=$(git rm file1 file2 2>&1) || true
		fi
	fi

	o_consistent=$(echo "$o_rm" | grep -v '^rm' | wc -l)
	if [ $o_consistent -ne 0 ]
	then
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
	lock_exists_output='''fatal: Unable to create '"'$replayed_snapshot"'/.git/refs/heads/master.lock'"'"': File exists.
				If no other git process is currently running, this probably means a
				git process crashed in this repository earlier. Make sure no other git
				process is running and remove the file manually to continue.'''
	o_lock_exists=$(diff <(echo "$o_commit" | sed 's/[ \t]//g' | grep -v '^$') <(echo "$lock_exists_output" | sed 's/[ \t]//g' | grep -v '^$') | wc -l)
	if [ -f $replayed_snapshot/.git/refs/heads/master.lock ]
	then
		if [ $o_lock_exists -ne 0 ]
		then
			echo "inconsistent, no-lock-warning"
			return
		fi
	fi
	if [ $o_lock_exists -eq 0 ]
	then
		# lock actually does exist
		echo 1 > $scratchpad/gchecker_$$/lock_found
		rm -f $replayed_snapshot/.git/refs/heads/master.lock
		o_commit=$(git commit -m "test3" 2>&1) || true
	fi
	o_correct_part="delete mode 100644 file1
			delete mode 100644 file2
			create mode 100644 file5"
	o_correct_tmp=$(echo "$o_commit" | grep -v '^\[master' | grep -v 'create mode 100644 file[34]' | grep -v '[35] files changed, 1 insertion' | sed 's/[ \t]//g' | grep -v '^$')
	o_consistent=$(diff <(echo "$o_correct_tmp") <(echo "$o_correct_part" | sed 's/[ \t]//g') | wc -l)
	if [ $o_consistent -ne 0 ]
	then
		echo "inconsistent, git-commit"
		return
	fi
	echo "consistent"
}

function post_checks {
	function check_data {
		file="$1"
		msg="$2"
		o_correct=$(diff $replayed_snapshot/$file /root/application_fs_bugs/alc-workloads/git/workload_dir/$file | wc -l)
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

	o_checkout=$(git checkout $first_commit_short 2>&1)
	correct_output="Note: checking out '$first_commit_short'.
			You are in 'detached HEAD' state. You can look around, make experimental
			changes and commit them, and you can discard any commits you make in this
			state without impacting any branches by performing another checkout.
			If you want to create a new branch to retain commits you create, you may
			do so (now or later) by using -b with the checkout command again. Example:
			git checkout -b new_branch_name
			HEAD is now at $first_commit_short... test1"
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
	correct_output="Previous HEAD position was $first_commit_short... test1
			Switched to branch 'master'"
	o_correct=$(diff <(echo "$correct_output" | sed 's/[ \t]//g' | grep -v '^$') <(echo "$o_checkout" | sed 's/[ \t]//g' | grep -v '^$') | wc -l)
	if [ $o_correct -ne 0 ]
	then
		echo "inconsistent, middle checkout"
		return
	fi

	if [ "$last_commit" != "$second_commit_short" ]
	then
		echo "consistent directory"
		return
	fi

	o_checkout=$(git checkout $second_commit_short 2>&1)
	correct_output="Note: checking out '$second_commit_short'.
			You are in 'detached HEAD' state. You can look around, make experimental
			changes and commit them, and you can discard any commits you make in this
			state without impacting any branches by performing another checkout.
			If you want to create a new branch to retain commits you create, you may
			do so (now or later) by using -b with the checkout command again. Example:
			git checkout -b new_branch_name
			HEAD is now at $second_commit_short... test2"
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

git config core.fsyncobjectfiles false

function do_it {
	refs_log_check_output=$(refs_log_check)
	echo "refs_log_check: $refs_log_check_output"
	short_summary=$(echo $refs_log_check_output | awk -F ',' '{print $1}')

	last_commit=$(echo $refs_log_check_output | awk '{print $2}')

	status_check_output=$(status_check $last_commit)
	echo "status_check: $status_check_output"
	short_summary="$short_summary; $status_check_output"

	fsck_check_output=$(fsck_check)
	echo "fsck_check: $fsck_check_output"
	fsck_dangling_ignored=$(echo "$fsck_check_output" | sed 's/dangling.*$/D/g' | tr -d '\n' | sed 's/^D\+$/consistentD/g')
	if [ "$fsck_dangling_ignored" != "consistent" ] && [ "$fsck_dangling_ignored" != "consistentD" ]
	then
		fsck_dangling_ignored="error"
	fi
	short_summary="$short_summary; $fsck_dangling_ignored"

	rm_add_commit_check_output=$(rm_add_commit_check $last_commit)
	echo "rm_add_commit_check: $rm_add_commit_check_output"
	short_summary="$short_summary; $rm_add_commit_check_output"

	post_checks_output=$(post_checks $last_commit)
	echo "post_checks: $post_checks_output"
	short_summary="$short_summary; $post_checks_output"

	echo "stdout:" $stdout
	short_stdout=$(echo -n S; echo $stdout | sed 's/add finished.*commit finished.*/AC/g' | sed 's/add finished.*/A/g' | grep '^A\?C\?$')
	short_summary="$short_summary; $short_stdout"

	echo "lock_found: $(cat $scratchpad/gchecker_$$/lock_found)"
	if [ $(cat $scratchpad/gchecker_$$/lock_found) -eq 1 ]
	then
		short_summary="$short_summary; L"
	fi

	echo "timed_out: $(cat $scratchpad/gchecker_$$/timed_out)"
	if [ $(cat $scratchpad/gchecker_$$/timed_out) -eq 1 ]
	then
		short_summary="$short_summary; T"
	fi

	echo "$short_summary" | sed 's/consistent/C/g' | sed 's/dangling/D/g' | sed 's/directory/dir/g' | sed 's/both tracked/T/g' | sed 's/both untracked/U/g' > $scratchpad/gchecker_$$/short_output
}

do_it  > /dev/null
#cp $scratchpad/gchecker_$$/short_output $scratchpad/gshort_output
cat $scratchpad/gchecker_$$/short_output
rm -rf $scratchpad/gchecker_$$
