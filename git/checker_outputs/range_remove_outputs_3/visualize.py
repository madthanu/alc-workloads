import sys
sys.path.append('/root/application_fs_bugs/alc-strace')
import visualize_crash_outputs as visualize

visualize.init_cmdline()

def converter(msg):
	if 'inC' in msg or 'insane' in msg:
		return '<td bgcolor=\'Red\' width=\'1\'></td>'
#		return visualize.color_cell('Red')
	else:
		return '<td bgcolor=\'Green\' width=\'1\'></td>'
#		return visualize.color_cell('Green')

visualize.visualize('\n', converter, './replay_output', './html_output.html')
