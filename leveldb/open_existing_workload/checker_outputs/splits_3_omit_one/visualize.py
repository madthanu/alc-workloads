#!/usr/bin/python
import sys
sys.path.append('/scratch/madthanu/application-fs-bugs/alc-strace')
import visualize_crash_outputs as visualize
import pprint
from collections import OrderedDict
import re

visualize.init_cmdline()

detailed = True

correct_states = ['\tC;C;;C;C;',
	"\tCorruption: 1 missing files; e.g.: /tmp/replayed_snapshot/testdb/000005.sst. checker: checker.cc:35: int main(int, char**): Assertion `ret.ok()' failed..;Corruption: 1 missing files; e.g.: /tmp/replayed_snapshot/testdb/000005.sst. checker: checker.cc:35: int main(int, char**): Assertion `ret.ok()' failed..;;C;C;",
	"\tCorruption: bad record length. checker: checker.cc:35: int main(int, char**): Assertion `ret.ok()' failed..;Corruption: bad record length. checker: checker.cc:35: int main(int, char**): Assertion `ret.ok()' failed..;;C;C;",
	"\tCorruption: checksum mismatch. checker: checker.cc:35: int main(int, char**): Assertion `ret.ok()' failed..;Corruption: checksum mismatch. checker: checker.cc:35: int main(int, char**): Assertion `ret.ok()' failed..;;C;C;",
	"\tCorruption: CURRENT file does not end with newline. checker: checker.cc:35: int main(int, char**): Assertion `ret.ok()' failed..;Corruption: CURRENT file does not end with newline. checker: checker.cc:35: int main(int, char**): Assertion `ret.ok()' failed..;;C;C;",
	"\tIO error: /tmp/replayed_snapshot/testdb/MANIFEST-000004: No such file or directory. checker: checker.cc:35: int main(int, char**): Assertion `ret.ok()' failed..;IO error: /tmp/replayed_snapshot/testdb/MANIFEST-000004: No such file or directory. checker: checker.cc:35: int main(int, char**): Assertion `ret.ok()' failed..;;C;C;"]

incorrect_states =["\tC;C;;checker: checker.cc:37: int main(int, char**): Assertion `replayed_entries == 2' failed..;checker: checker.cc:37: int main(int, char**): Assertion `replayed_entries == 2' failed..;",
	"\tchecker: checker.cc:37: int main(int, char**): Assertion `replayed_entries == 2' failed..;checker: checker.cc:37: int main(int, char**): Assertion `replayed_entries == 2' failed..;;C;C;",
	"\tCorruption: 1 missing files; e.g.: /tmp/replayed_snapshot/testdb/000005.sst. checker: checker.cc:35: int main(int, char**): Assertion `ret.ok()' failed..;Corruption: 1 missing files; e.g.: /tmp/replayed_snapshot/testdb/000005.sst. checker: checker.cc:35: int main(int, char**): Assertion `ret.ok()' failed..;;checker: checker.cc:37: int main(int, char**): Assertion `replayed_entries == 2' failed..;checker: checker.cc:37: int main(int, char**): Assertion `replayed_entries == 2' failed..;"]

colormap = OrderedDict()
legend = OrderedDict()

colormap[incorrect_states[0]] = '#FF0000'
legend[incorrect_states[0]] = 'Works fine initially; durability violated after recovery'

colormap[incorrect_states[1]] = '#994400'
legend[incorrect_states[1]] = 'Initial durability violation (silent); fine afterwards'

colormap[incorrect_states[2]] = '#FFFF00'
legend[incorrect_states[2]] = 'Initial corruption; durability violated after recovery'

for x in correct_states[1:]:
	colormap[x] = '#00FF00'
	legend[x] = 'Initial corruption; correct after recovery'

colormap[correct_states[0]] = '#009900'
legend[correct_states[0]] = 'Correct'

def converter(msg, situation, width=''):
	msg = re.sub(r'/tmp/replayed_snapshot/[0-9]+/', '/tmp/replayed_snapshot/', msg)
	global correct_states, incorrect_states, colormap
	if not (msg in correct_states or msg in incorrect_states):
		print 'Unhandled msg: ' + repr(msg)
	assert msg in correct_states or msg in incorrect_states
	assert msg in colormap
	if width != '':
		width = 'width=' + str(width)
	return "<td %s bgcolor='%s' onclick=\"window.document.title='%s';return true\"></td>" % (width, colormap[msg], situation)

def get_legend():
	toret = OrderedDict()
	for state in legend.keys():
		toret[legend[state]] = converter(state, '', 5)
	return toret

visualize.visualize('\n', converter, get_legend(), './replay_output', './html_output.html')

