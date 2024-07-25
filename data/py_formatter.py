import sys
import os

maindir = (sys.argv[1])

auto_del  = []
no_del = []

# this is a fixed list of talkgroup IDs that will be affected by the auto-deletion
talkgroups_path = os.path.join(maindir, "data/talkgroups.txt")
with open(talkgroups_path,'r') as talkgroups:
	main_list = []
	for lines in talkgroups:
		main_list.append(lines.strip())

# this appends the long duration call talkgroup IDs  retrieved by the query script into a list.
formatter_path = os.path.join(maindir, "data/formatter.input")
with open(formatter_path, 'r') as file1:
	calls = []
	for lines in file1:
		calls.append(lines.strip())

# this section splits the calls that are sats and non-sats
for ID in calls:
	if ID in main_list:
		auto_del.append(ID)
	else:
		no_del.append(ID)

if len(auto_del) != 0:
	auto_del_path = os.path.join(maindir, "data/auto_del.tmp")
	with open(auto_del_path,'a+') as x:
		auto_del = str(auto_del)
		auto_del = auto_del.replace('[', '(').replace(']', ')').replace(" ","")
		x.write(auto_del)

if len(no_del) != 0:
	no_del_path = os.path.join(maindir, "data/no_del.tmp")
	with open(no_del_path,'a+') as y:
		no_del = str(no_del)
		no_del = no_del.replace('[', '(').replace(']', ')').replace(" ","")
		y.write(no_del)
