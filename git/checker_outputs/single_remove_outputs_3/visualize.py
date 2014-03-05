#!/usr/bin/python
import sys
sys.path.append('/scratch/madthanu/application-fs-bugs/alc-strace')
import visualize_crash_outputs as visualize
import pprint
from collections import OrderedDict

visualize.init_cmdline()

detailed = True

correct_states = ['\tC; C, T; C; C; C dir',
     '\tC; C, T; C; C; C dir; L',
     '\tC; C, T; CD; C; C dir',
     '\tC; C, T; CD; C; C dir; L',
     '\tC; C, U; C; C; C dir',
     '\tC; C, U; C; C; C dir; L',
     '\tC; C, U; CD; C; C dir',
     '\tC; C, U; CD; C; C dir; L',
     '\tC; C; C; C; C dir',
     '\tC; C; C; C; C dir; L']


incorrect_states = ['\tC; C, T; C; inC, git-add; inC checkout, first commit; T',
     '\tC; C, T; error; C; C dir',
     '\tC; C, T; error; C; C dir; L',
     '\tC; C, T; error; inC, git-commit; inC checkout, first commit',
     '\tC; C, T; error; inC, no-lock-warning; inC checkout, first commit',
     '\tC; C; error; C; C dir',
     '\tC; inC; C; inC, git-rm; inC dir after all commit operations',
     '\tC; inC; CD; inC, git-rm; inC dir after all commit operations',
     '\tC; inC; CD; inC, git-rm; inC dir after all commit operations; L',
     '\tC; inC; error; inC, git-rm; inC dir after all commit operations',
     '\tC; inC; error; inC, git-rm; inC dir after all commit operations; L',
     '\tinsane o1; inC; error; inC, git-rm; inC dir after all commit operations',
     '\tinsane o1; inC; error; inC, git-rm; inC dir after all commit operations; L',
     '\tinsane o3; C, T; C; C; C dir',
     '\tinsane o3; C, T; C; C; C dir; L',
     '\tinsane o3; C, T; CD; C; C dir; L',
     '\tinsane o3; C, T; error; C; C dir; L',
     '\tinsane o3; C, T; error; inC, no-lock-warning; inC checkout, first commit',
     '\tinsane o3; inC; C; C; C dir',
     '\tinsane o3; inC; C; inC, git-rm; inC dir after all commit operations',
     '\tinsane o3; inC; error; inC, git-rm; inC dir after all commit operations',
     '\tC; C; error; inC, git-commit; inC checkout, first commit']

colormap = OrderedDict()
# YELLOW - error fsck; no other problem. Shades represent progress.
colormap['\tC; C, T; error; C; C dir'] = '#888800'
colormap['\tC; C, T; error; C; C dir; L'] = '#888800'
colormap['\tC; C; error; C; C dir'] = '#FFFF00'

# BLUE - error fsck; other problems (except insane o3)
colormap['\tC; C, T; error; inC, git-commit; inC checkout, first commit'] = '#0000FF'
colormap['\tC; C, T; error; inC, no-lock-warning; inC checkout, first commit'] = '#0000FF'
colormap['\tC; C; error; inC, git-commit; inC checkout, first commit'] = '#0000FF'
colormap['\tC; inC; error; inC, git-rm; inC dir after all commit operations'] = '#0000AA'
colormap['\tC; inC; error; inC, git-rm; inC dir after all commit operations; L'] = '#0000AA'
colormap['\tinsane o1; inC; error; inC, git-rm; inC dir after all commit operations']= '#000088'
colormap['\tinsane o1; inC; error; inC, git-rm; inC dir after all commit operations; L'] = '#000088'
colormap['\tinsane o3; C, T; error; inC, no-lock-warning; inC checkout, first commit'] = '#000066'
colormap['\tinsane o3; inC; error; inC, git-rm; inC dir after all commit operations'] = '#000044'

# BROWN - problem with only o3
colormap['\tinsane o3; C, T; C; C; C dir'] = '#FF00FF'
colormap['\tinsane o3; C, T; C; C; C dir; L'] = '#FF00FF'
colormap['\tinsane o3; C, T; CD; C; C dir; L'] = '#FF00FF'
colormap['\tinsane o3; C, T; error; C; C dir; L'] = '#AA00AA'

# RED - no error fsck; other problems
colormap['\tC; inC; C; inC, git-rm; inC dir after all commit operations'] = '#FF0000'
colormap['\tC; inC; CD; inC, git-rm; inC dir after all commit operations'] = '#FF0000'
colormap['\tC; inC; CD; inC, git-rm; inC dir after all commit operations; L'] = '#FF0000'
colormap['\tinsane o3; inC; C; C; C dir'] = '#AA0000'
colormap['\tinsane o3; inC; C; inC, git-rm; inC dir after all commit operations'] = '#660000'

# Some color - for the timeout case
colormap['\tC; C, T; C; inC, git-add; inC checkout, first commit; T'] = '#FFAAAA'

for state in incorrect_states:
	assert state in colormap

def converter(msg, situation):
	global correct_states, incorrect_states, colormap
	if msg in correct_states:
		if not detailed:
			return visualize.color_cell('Green')
		msg = msg.split(';')
		durability_stage = msg[1].strip()
		if durability_stage == 'C':
			color = '#00ff00'
		elif durability_stage == 'C, T':
			color = '#008800'
		else:
			assert durability_stage == 'C, U'
			color = '#004400'
		fsck_output = msg[2].strip()
		if fsck_output == 'CD':
			first_visibility = 'visible'
		else:
			assert fsck_output == 'C'
			first_visibility = 'hidden'

		lock_present = msg[-1].strip() == 'L'
		if lock_present:
			second_visibility = 'visible'
		else:
			second_visibility = 'hidden'

		html_output = "<td onclick='window.document.title=\"%s\"' bgcolor='%s'>" \
				"<div style='color:#ff0000; font-weight:bold; visibility:%s'>DD</div>" \
				"<div style='color:#ffffff; font-weight:bold; visibility:%s'>LL</div>" \
				"</td>" % (situation, color, first_visibility, second_visibility)
		return html_output
	elif msg in incorrect_states:
		if not detailed:
			return visualize.color_cell('Red')
		return "<td onclick='window.document.title=\"%s\"' bgcolor='%s'></td>" % (situation, colormap[msg])
	else:
		print 'Unhandled: ' + msg
		assert False

def get_legend():
	toret = OrderedDict()
	for state in colormap:
		toret[state] = converter(state, '')
	for state in correct_states:
		toret[state] = converter(state, '')
	return toret

visualize.visualize('\n', converter, get_legend(), './short_outputs', './html_output.html')

