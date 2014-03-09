import datetime
import copy
load(0)

# NOTE: There is one important distinction between the remove() calls and the
# omit() calls. While removing, you actually end up changing the index number
# of every disk_op/micro_op after the current one. Omitting leaves the index
# numbers as such. Thus, "dops_remove(31); dops_remove(31); dops_remove(31);"
# removes three separate disk operations. However, "dops_omit(31);
# dops_omit(31); dops_omit(31);" omits only one oepration.

def prefix_run(start, end):
	load(0)

	for i in range(start, end + 1):
		keep_list = range(0, i + 1)
		checker_params = dops_implied_stdout(keep_list)

		E = str(i) + str(dops_double(i))
		dops_end_at(dops_double(i))
		dops_replay(str(datetime.datetime.now()) +
				' E' + E, checker_params = checker_params)

def omit_one_heuristic(start, end):
	load(0)

	for i in range(start, end + 1):
		keep_list = range(0, i)
		till = dops_single(dops_independent_till(dops_double(i)))

		for j in range(i + 1, end + 1):
			keep_list.append(j)
			checker_params = dops_implied_stdout(keep_list)

			R = str(i) + str(dops_double(i))
			E = str(j) + str(dops_double(j))
			dops_end_at(dops_double(j))
			dops_omit(dops_double(i))
			dops_replay('R' + R + ' E' + E, checker_params = checker_params)
			
			load(0)
def omit_range_heuristic():
	load(0)

	# 'i' is the beginning of the range to be omitted.
	for i in range(0, dops_len()):

		# 'drop_set' contains the set of operations that are to be
		# omitted. i.e., all operations which fall within the range.
		drop_set = [dops_double(i)]

		# 'j' is the end of the range to be omitted.
		for j in range(i + 1, dops_len()):
			drop_set.append(dops_double(j))
			till = dops_single(dops_independent_till(drop_set))
			
			if till < j:
				break

			# 'k' is the disk_op till which the trace is to be
			# replayed after omitting the range previously decided.
			for k in range(j + 1, till + 1):
				R = str(i) + str(dops_double(i)) + '...' + str(j) + str(dops_double(j))
				E = str(k) + str(dops_double(k))

				# end at k
				dops_end_at(dops_double(k))

				# omit everything in the drop set
				for drop_op in drop_set: dops_omit(drop_op)

				dops_replay(str(datetime.datetime.now()) +
							' R' + R +
							' E' + E)
				load(0)

def example_calls():
	load(0)

	# set_garbage(3)
	# Set the micro-op of index 3 as garbage. (It should
	# be a write or append.) This will work, but I don't see why we'd be
	# using this now, as will replay_and_check() that replays using
	# micro-ops. Also, if this call is used, dops_generate() should be used
	# to generate the corresponding disk-ops.

	dops_generate(splits = 4) # Generate disk ops from micro op, splitting each append, write, and truncate micro-op into four disk ops
	dops_generate(4, splits = 10) # Split micro-op with index 4 into ten disk ops 
	dops_generate([8, 9, 10], splits = 1) # Generate disk ops from the micro-ops with index 8, 9, and 10, without any splitting
	save(1)
	dops_set_legal() # Tells the framework that the current displayed set of disk ops is the one that should be considered correct/legal.


	load(1)
	dops_omit(dops_double(1))
	dops_end_at(dops_double(2))
	dops_replay()

#dops_replay(checker_params=(3, 'beforeafter', 'beforeafter'))
for i in range(0, len(micro_ops)):
	op = get_op(i)
	if op.op == 'stdout':
		if 'opened' in op.data:
			for j in range(i + 1, len(micro_ops)):
				if get_op(j).op != 'stdout':
					start = j
					break
		if 'closing' in op.data:
			for j in range(i, -1, -1):
				if get_op(j).op != 'stdout':
					end = j
					break

#start = dops_single((start, 0))
#end = dops_single((end, 0)) + 1 # Adding 1 to the end ... making sure omit_one invokes the case where that #last operation is omitted ## Doesn't prefix already take care of this?
#print (start, end)
#omit_one_heuristic(start, end)
print dops_len()
omit_one_heuristic(0, dops_len() - 1)
#prefix_run(0, dops_len() - 1)
