#!/usr/bin/python
import sys
sys.path.append('/scratch/madthanu/application-fs-bugs/alc-strace')
import visualize_crash_outputs as visualize
import pprint
from collections import OrderedDict
import re

visualize.init_cmdline()

detailed = True

['\tC;C;;C;C;',
 "\tC;Corruption: bad record length. checker: checker.cc:35: int main(int, char**): Assertion `ret.ok()' failed..;;C;C;",
 "\tC;Corruption: checksum mismatch. checker: checker.cc:35: int main(int, char**): Assertion `ret.ok()' failed..;;checker: ../myutils.h:67: int read_and_verify(leveldb::DB*, int, int): Assertion `false' failed..key and it->key() mismatch. Expected: c, Got: ccccc(5000 chars, last char: 0).;Corruption: checksum mismatch. checker: checker.cc:35: int main(int, char**): Assertion `ret.ok()' failed..;",
 "\tC;Corruption: checksum mismatch. checker: checker.cc:35: int main(int, char**): Assertion `ret.ok()' failed..;;checker: ../myutils.h:71: int read_and_verify(leveldb::DB*, int, int): Assertion `false' failed..value and it->value() mismatch. Expected: C, Got: CDEFG(5000 chars, last char: 0).;Corruption: checksum mismatch. checker: checker.cc:35: int main(int, char**): Assertion `ret.ok()' failed..;"]

correct_states = ['\tC;C;;C;C;',
 "\tC;Corruption: bad record length. checker: checker.cc:35: int main(int, char**): Assertion `ret.ok()' failed..;;C;C;"]

incorrect_states = ["\tC;Corruption: checksum mismatch. checker: checker.cc:35: int main(int, char**): Assertion `ret.ok()' failed..;;checker: ../myutils.h:67: int read_and_verify(leveldb::DB*, int, int): Assertion `false' failed..key and it->key() mismatch. Expected: c, Got: ccccc(5000 chars, last char: 0).;Corruption: checksum mismatch. checker: checker.cc:35: int main(int, char**): Assertion `ret.ok()' failed..;",
 "\tC;Corruption: checksum mismatch. checker: checker.cc:35: int main(int, char**): Assertion `ret.ok()' failed..;;checker: ../myutils.h:71: int read_and_verify(leveldb::DB*, int, int): Assertion `false' failed..value and it->value() mismatch. Expected: C, Got: CDEFG(5000 chars, last char: 0).;Corruption: checksum mismatch. checker: checker.cc:35: int main(int, char**): Assertion `ret.ok()' failed..;",
"\tC;Corruption: checksum mismatch. checker: checker.cc:35: int main(int, char**): Assertion `ret.ok()' failed..;;checker: ../myutils.h:67: int read_and_verify(leveldb::DB*, int, int): Assertion `false' failed..key and it->key() mismatch. Expected: c, Got: ccccc(5000 chars, last char: 0).;checker: ../myutils.h:67: int read_and_verify(leveldb::DB*, int, int): Assertion `false' failed..key and it->key() mismatch. Expected: c, Got: ccccc(5000 chars, last char: 0).;",
"\tC;Corruption: checksum mismatch. checker: checker.cc:35: int main(int, char**): Assertion `ret.ok()' failed..;;checker: ../myutils.h:71: int read_and_verify(leveldb::DB*, int, int): Assertion `false' failed..value and it->value() mismatch. Expected: C, Got: CDEFG(5000 chars, last char: 0).;checker: ../myutils.h:71: int read_and_verify(leveldb::DB*, int, int): Assertion `false' failed..value and it->value() mismatch. Expected: C, Got: CDEFG(5000 chars, last char: 0).;"]


colormap = OrderedDict()
legend = OrderedDict()

for x in incorrect_states[0:2]:
	colormap[x] = '#AA00AA'
	legend[x] = 'Correct initially without checksum checking, but exception with checksums; after recovery, silent corruption without checksums, exception (detected corruption) with checksums'

for x in incorrect_states[2:4]:
	colormap[x] = '#FF0000'
	legend[x] = 'Correct initially without checksum checking, but exception with checksums; after recovery, silent corruption with or without checksums'

colormap[correct_states[1]] = '#66FF'
legend[correct_states[1]] = 'Initial exception when opened with checksums, fine without checksums; correct after recovery'

colormap[correct_states[0]] = '#009900'
legend[correct_states[0]] = 'Correct'

def converter(msg, situation, width=5):
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

