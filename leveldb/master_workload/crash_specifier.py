import datetime
import copy
import os
alc_strace_path = os.path.abspath(__file__)
alc_strace_path = alc_strace_path[0 : alc_strace_path.find('/alc-workloads')] + '/alc-strace'
import sys
sys.path.append(alc_strace_path)
import conv_micro
load(0)

# NOTE: There is one important distinction between the remove() calls and the
# omit() calls. While removing, you actually end up changing the index number
# of every disk_op/micro_op after the current one. Omitting leaves the index
# numbers as such. Thus, "dops_remove(31); dops_remove(31); dops_remove(31);"
# removes three separate disk operations. However, "dops_omit(31);
# dops_omit(31); dops_omit(31);" omits only one oepration.

def prefix_run(msg, consider_only = None):
	for i in range(0, dops_len()):
		op = get_op(dops_double(i)[0]).op
		if consider_only and (not op in consider_only):
			continue
		if op == 'sync':
			continue
		E = str(i) + str(dops_double(i))
		dops_end_at(dops_double(i))
		dops_replay(msg + ' E' + E)
	print 'finished ' + msg

def omit_one(msg, consider_only = None):
	for i in range(0, dops_len()):
		op = get_op(dops_double(i)[0]).op
		if op in conv_micro.pseudo_ops:
			continue
		if consider_only and (not op in consider_only):
			continue
		till = dops_single(dops_independent_till(dops_double(i)))

		for j in range(i + 1, till + 1):
			op = get_op(dops_double(j)[0]).op
			if op in conv_micro.sync_ops:
				continue
			R = str(i) + str(dops_double(i))
			E = str(j) + str(dops_double(j))
			dops_end_at(dops_double(j))
			dops_omit(dops_double(i))
			dops_replay(msg + ' R' + R + ' E' + E)
			dops_include(dops_double(i))
	print 'finished ' + msg

#omit_one('omit_one-three')
#omit_one('omit_one')
print dops_len()
