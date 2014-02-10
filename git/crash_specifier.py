import datetime
load(0)

if True:
	load(0)
	R = dops_double(128)
	E = (37,5)
	dops_end_at(E)
	dops_omit(R)
	dops_replay()

if False:
	all_combos = []
	combos_count = 0
	load(0)
	for i in range(0, dops_len()):
		drop_set = [dops_double(i)]
		for j in range(i + 1, dops_len()):
			drop_set.append(dops_double(j))
			till = dops_independent_till(drop_set)
			print('Combos count: ' + str((dops_double(i), dops_double(j))) + ' ' + str(combos_count) + ' ' + str(till))
			till = dops_single(till)
			if till < j:
				break
			combos_count += (till - j)
			for k in range(j + 1, till + 1):
				all_combos.append((i, j, k))

	print 'Done getting all_combos.'
	print combos_count
	all_combos.reverse()

if False:
	last = 0
	for i in range(0, dops_len()):
		load(0)
		till = dops_single(dops_independent_till(dops_double(i)))
		for j in range(i + 1, till + 1):
			load(0)
			#assert (i, j) == all_combos.pop()
			R = str(i) + str(dops_double(i))
			E = str(j) + str(dops_double(j))
			end_at(dops_double(j))
			dops_remove(dops_double(i))
			last = (i, j)
			dops_replay(str(datetime.datetime.now()) +
						' R' + R +
						' E' + E)
	load(0)
	print last
	print (dops_len() - 2, dops_len() - 1)
	assert last == (dops_len() - 2, dops_len() - 1)

if False:
	load(0)
	for i in range(0, dops_len()):
		drop_set = [dops_double(i)]
		for j in range(i + 1, dops_len()):
			drop_set.append(dops_double(j))
			till = dops_single(dops_independent_till(drop_set))
			if till < j:
				break
			for k in range(j + 1, till + 1):
				#assert (i, j, k) == all_combos.pop()
				R = str(i) + str(dops_double(i)) + '...' + str(j) + str(dops_double(j))
				E = str(k) + str(dops_double(k))
				dops_end_at(dops_double(k))
				for drop_op in reversed(drop_set): dops_omit(drop_op)
				dops_replay(str(datetime.datetime.now()) +
							' R' + R +
							' E' + E)
				load(0)

print 'Done crash specification.'
#_dops_verify_replayer()
#auto_test(limit = 10)
#for i in range(0, 11):
#	load(0)
#	end_at(i)
#	replay_and_check()
#for i in range(6,11):
#	load(0)
#	#end_at(i)
#	remove(i)
#	replay_and_check(i)
#auto_test(limit=10)
#export_pickle('/tmp/a')
