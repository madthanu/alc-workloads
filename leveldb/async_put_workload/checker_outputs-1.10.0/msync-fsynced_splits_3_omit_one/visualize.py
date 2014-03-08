#!/usr/bin/python
import sys
sys.path.append('/scratch/madthanu/application-fs-bugs/alc-strace')
import visualize_crash_outputs as visualize
import pprint
from collections import OrderedDict
import re

visualize.init_cmdline()

detailed = True



def initial_filter(line):
	line = line.strip()
	line = re.sub(r'; e\.g\.', ' eg', line)
	parts = line.split(';')
	assert len(parts) == 6
	for i in range(0, len(parts)):
		if 'key and it->key() mismatch.' in parts[i] or 'value and it->value() mismatch.' in parts[i]:
			parts[i] = 'Silent corruption'
		elif 'Assertion `character_present[i + \'a\'] == 1\' failed' in parts[i]:
			parts[i] = 'Silent consistency'
		elif 'Assertion `ret.ok()\' failed.' in parts[i]:
			parts[i] = 'Exception'
		elif 'Assertion `replayed_entries >= 2\' failed.' in parts[i]:
			parts[i] = 'Durability silent'
		elif parts[i] in ['C', '']:
			parts[i] = parts[i]
		else:
			print line
			print parts[i]
			assert False
	return ';'.join(parts)


incorrect_states = [
 'C;C;;Durability silent;Durability silent;',
 'C;C;;Silent consistency;Silent consistency;',
 'C;Exception;;Durability silent;Durability silent;',
 'C;Exception;;Silent corruption;Silent corruption;',
 'Durability silent;Durability silent;;C;C;',
 'Silent consistency;Silent consistency;;C;C;',
 'Durability silent;Exception;;C;C;',
 'Durability silent;Exception;;Silent corruption;Silent corruption;',
 'Exception;Exception;;Durability silent;Durability silent;',
 'Exception;Exception;;Silent consistency;Silent consistency;',
 'Exception;Exception;;Silent corruption;Silent corruption;',
]

correct_states = ['C;C;;C;C;',
	'C;Exception;;C;C;',
	'Exception;Exception;;C;C;']

colormap = OrderedDict()
legend = OrderedDict()

colormap[correct_states[0]] = '#00AA00'
legend[correct_states[0]] = 'Correct'

for state in correct_states[1:]:
	colormap[state] = '#44FF00'
	legend[state] = 'Exception before recovery, sometimes only with checksum-checking; fine afterwards'

for state in incorrect_states[0:2]:
	colormap[state] = '#FF0000'
	legend[state] = 'Correct with or without checksums before recovery; Silent consistency or durability problems afterwards'

for state in incorrect_states[2:4]:
	colormap[state] = '#990000'
	legend[state] = 'Correct without checksums before recovery, exception with checksums; Silent corruption or durability problems afterwards'

for state in incorrect_states[4:6]:
	colormap[state] = '#0000FF'
	legend[state] = 'Silent durability or consistency problems before recovery (with or without checksums); fine afterwards'

for state in incorrect_states[6:7]:
	colormap[state] = '#000099'
	legend[state] = 'Silent durability without checksums before recovery, exception with checksums); fine afterwards'

for state in incorrect_states[7:8]:
	colormap[state] = '#777777'
	legend[state] = 'Silent durability without checksums before recovery, exception with checksums); silent corruption afterwards'

for state in incorrect_states[8:11]:
	colormap[state] = '#000000'
	legend[state] = 'Exception always before recovery; silent corruption/durability/consistency problems afterwards'
 
#uniq_msgs=set()

def converter(msg, situation, width = '', filter = True):
	msg = re.sub(r'/tmp/replayed_snapshot/[0-9]+/', '/tmp/replayed_snapshot/', msg)
	if filter:
		msg = initial_filter(msg)
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
		toret[legend[state]] = converter(state, '', 5, False)
	return toret

visualize.visualize('\n', converter, get_legend(), './replay_output', './html_output.html')

