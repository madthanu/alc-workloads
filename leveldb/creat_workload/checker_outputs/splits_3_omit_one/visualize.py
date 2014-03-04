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
	"\tCorruption: CURRENT file does not end with newline. checker: checker.cc:35: int main(int, char**): Assertion `ret.ok()' failed..;Corruption: CURRENT file does not end with newline. checker: checker.cc:35: int main(int, char**): Assertion `ret.ok()' failed..;;C;C;",
	"\tCorruption: bad record length. checker: checker.cc:35: int main(int, char**): Assertion `ret.ok()' failed..;Corruption: bad record length. checker: checker.cc:35: int main(int, char**): Assertion `ret.ok()' failed..;;C;C;",
	"\tCorruption: checksum mismatch. checker: checker.cc:35: int main(int, char**): Assertion `ret.ok()' failed..;Corruption: checksum mismatch. checker: checker.cc:35: int main(int, char**): Assertion `ret.ok()' failed..;;C;C;",
	"\tCorruption: no meta-nextfile entry in descriptor. checker: checker.cc:35: int main(int, char**): Assertion `ret.ok()' failed..;Corruption: no meta-nextfile entry in descriptor. checker: checker.cc:35: int main(int, char**): Assertion `ret.ok()' failed..;;C;C;",
	"\tIO error: /tmp/replayed_snapshot/testdb/MANIFEST-000001: No such file or directory. checker: checker.cc:35: int main(int, char**): Assertion `ret.ok()' failed..;IO error: /tmp/replayed_snapshot/testdb/MANIFEST-000001: No such file or directory. checker: checker.cc:35: int main(int, char**): Assertion `ret.ok()' failed..;;C;C;",
	"\tIO error: /tmp/replayed_snapshot/testdb/MANIFEST-000002: No such file or directory. checker: checker.cc:35: int main(int, char**): Assertion `ret.ok()' failed..;IO error: /tmp/replayed_snapshot/testdb/MANIFEST-000002: No such file or directory. checker: checker.cc:35: int main(int, char**): Assertion `ret.ok()' failed..;;C;C;"]

incorrect_states = []

colormap = OrderedDict()
legend = OrderedDict()

colormap[correct_states[0]] = '#00AA00'
legend[correct_states[0]] = 'Correct'

for state in correct_states[1:]:
	colormap[state] = '#44FF00'
	legend[state] = 'Corruption before recovery; fine afterwards'

#uniq_msgs=set()

def converter(msg, situation, width = ''):
	msg = re.sub(r'/tmp/replayed_snapshot/[0-9]+/', '/tmp/replayed_snapshot/', msg)
	global correct_states, incorrect_states, colormap
	if not (msg in correct_states or msg in incorrect_states):
		print 'Correct msg  : ' + repr(correct_states[5])
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

