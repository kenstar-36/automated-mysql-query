# automated-mysql-query
Automated querying for MySQL database, with conditions to send email alerts and perform actions such as issuing DELETE commands to the MYSQL database.

Created by: [REDACTED]

This script automates the process of querying the DBU and sending out mail alerts when conditions are met. It uses both BASH and Python.
There is also a function to automatically delete calls that exceed the $duration_limit .

There are multiple components that makes this work;
The main script, and its sub-components stored in data/ and logs/.

1. query_and_delete.sh (main script)
	- This is the main script.
	- Its function is to query the MySQL database, handle some exceptions, and perform actions such as sending an email alert or issue a DELETE command to the database for long duration calls.
	- Query results are also passed to a python script (next item) for additional formatting.
	- It is dependent on the files in the data/ directory.
	- The outcome of each condition is also logged in the logs/ directory.

2. data/Active-DBU.status
	- This file is where the query results are stored to be procesed.
	- The data in this file will automatically be deleted when the script had finished running.
	- The logs are where past query results are stored.

3. data/talkgroups.txt
	- This text file requires manual input from the user. Talkgroup IDs that are found in this text file and the query result will be automatically deleted.

4. data/py_formatter.py
	- This python script formats the query results in such a way that allows the main script to use the output as a variable for DELETE commands.
	- This python script also creates 2 temporary files in the data/ directory; which are auto_del.tmp and no_del.tmp.
	- auto_del.tmp is created if a talkgroup ID is found in both the query result and data/talkgroups.txt.
	- no_del.tmp is created when the query result returns a long duration call from any talkgroups.

5. logs/
	- This directory contains the log of the script for the past 6 hours.
	- The sub-directory logs/archive is where log files are archived.
	- You can check the cronjob for user [REDACTED] for more details.
