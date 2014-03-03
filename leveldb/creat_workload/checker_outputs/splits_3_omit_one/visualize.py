#!/usr/bin/python
import sys
sys.path.append('/scratch/madthanu/application-fs-bugs/alc-strace')
import visualize_crash_outputs as visualize
import pprint
from collections import OrderedDict
import re

visualize.init_cmdline()

detailed = True

correct_states = ['\tC;C;;C;C;']


incorrect_states =["\tCorruption: CURRENT file does not end with newline. checker: checker.cc:37: int main(int, char**): Assertion `ret.ok()' failed..;Corruption: CURRENT file does not end with newline. checker: checker.cc:37: int main(int, char**): Assertion `ret.ok()' failed..;;C;Corruption: CURRENT file does not end with newline. checker: checker.cc:37: int main(int, char**): Assertion `ret.ok()' failed..;",
     "\tCorruption: bad record length. checker: checker.cc:37: int main(int, char**): Assertion `ret.ok()' failed..;Corruption: bad record length. checker: checker.cc:37: int main(int, char**): Assertion `ret.ok()' failed..;;C;Corruption: bad record length. checker: checker.cc:37: int main(int, char**): Assertion `ret.ok()' failed..;",
     "\tCorruption: checksum mismatch. checker: checker.cc:37: int main(int, char**): Assertion `ret.ok()' failed..;Corruption: checksum mismatch. checker: checker.cc:37: int main(int, char**): Assertion `ret.ok()' failed..;;C;Corruption: checksum mismatch. checker: checker.cc:37: int main(int, char**): Assertion `ret.ok()' failed..;",
     "\tCorruption: no meta-nextfile entry in descriptor. checker: checker.cc:37: int main(int, char**): Assertion `ret.ok()' failed..;Corruption: no meta-nextfile entry in descriptor. checker: checker.cc:37: int main(int, char**): Assertion `ret.ok()' failed..;;C;Corruption: no meta-nextfile entry in descriptor. checker: checker.cc:37: int main(int, char**): Assertion `ret.ok()' failed..;",
     "\tIO error: /tmp/replayed_snapshot/testdb/MANIFEST-000001: No such file or directory. checker: checker.cc:37: int main(int, char**): Assertion `ret.ok()' failed..;IO error: /tmp/replayed_snapshot/testdb/MANIFEST-000001: No such file or directory. checker: checker.cc:37: int main(int, char**): Assertion `ret.ok()' failed..;;C;IO error: /tmp/replayed_snapshot/testdb/MANIFEST-000001: No such file or directory. checker: checker.cc:37: int main(int, char**): Assertion `ret.ok()' failed..;",
     "\tIO error: /tmp/replayed_snapshot/testdb/MANIFEST-000002: No such file or directory. checker: checker.cc:37: int main(int, char**): Assertion `ret.ok()' failed..;IO error: /tmp/replayed_snapshot/testdb/MANIFEST-000002: No such file or directory. checker: checker.cc:37: int main(int, char**): Assertion `ret.ok()' failed..;;C;IO error: /tmp/replayed_snapshot/testdb/MANIFEST-000002: No such file or directory. checker: checker.cc:37: int main(int, char**): Assertion `ret.ok()' failed..;"]

colormap = OrderedDict()

for state in incorrect_states:
	colormap[state] = '#FF0000'

for state in correct_states:
	colormap[state] = '#00AA00'

#uniq_msgs=set()

def converter(msg, situation):
	msg = re.sub(r'/tmp/replayed_snapshot/[0-9]+/', '/tmp/replayed_snapshot/', msg)
#	global uniq_msgs
#	uniq_msgs.add(msg)
#	return ''
	global correct_states, incorrect_states, colormap
	if not (msg in correct_states or msg in incorrect_states):
		print 'Unhandled msg: ' + repr(msg)
	assert msg in correct_states or msg in incorrect_states
	assert msg in colormap
	return "<td bgcolor='%s' onclick=\"window.document.title='%s';return true\"></td>" % (colormap[msg], situation)

def get_legend():
	toret = OrderedDict()
	for state in colormap:
		toret[state] = converter(state, '')
	return toret

visualize.visualize('\n', converter, get_legend(), './replay_output', './html_output.html')

