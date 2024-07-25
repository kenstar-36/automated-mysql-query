#!/bin/bash

key=$(echo '[REDACTED]' | base64 --decode)
node=$(echo '[REDACTED]' | base64 --decode)	#refers to VIP

duration_limit="900"
query="mysql -u[REDACTED] -p$key scu -Be 'set @currTime = CURRENT_TIMESTAMP(); select PTT_CALL_ID, CLG_PTT_ID, CALL_ID, START_TIME, @currTime, TIME_TO_SEC(timediff(@currTime,START_TIME)) from PTT_AS_CALL where CALL_TYPE != 5 AND TIME_TO_SEC(timediff(@currTime,START_TIME)) > $duration_limit order by TIME_TO_SEC(timediff(@currTime,START_TIME)) desc limit 10;'"

main_dir="[REDACTED]/DB_Garbage_Call_Finder"
state="$main_dir/data/Active-DBU.status"
talkgroups="$main_dir/data/talkgroups.txt"
py_formatter="$main_dir/data/py_formatter.py"
formatter_in="$main_dir/data/formatter.input"
auto_del="$main_dir/data/auto_del.tmp"
no_del="$main_dir/data/no_del.tmp"
script_log="$main_dir/logs/$(date +'%Hhr%d-%m-%Y').script.log"   #This log file records the exit status of the loops below
timestamp=$(date '+%d-%m-%Y %H:%M:%S')

v_To='[REDACTED]'
v_CC=''
v_BCC=''
sender="[REDACTED]"
auto_del_subj="Long Duration calls from targeted talkgroups detected and removed on Active DBU! "$timestamp""
auto_del_cont="They were removed automatically. Please check the active DBU.                                                                                                                                                                                    "
no_del_subj="Long Duration calls from non-targeted talkgroups detected on Active DBU! "$timestamp""
no_del_cont="Please check the active DBU and alert the whatsapp group!                                                                                                                                                                                          "
# fetch any calls longer than $duration_limit from the Active DBU.
ssh -t si@"$node" "echo '$timestamp -(QUERY)	$node' ; $query" | tee  $state | tee -a $script_log

# check for any unexpected issues
if grep -q "(QUERY)" "$state";then
break
else
echo "$timestamp -(ERROR)       The script encountered an unexpected condition. Please log in to the server for troubleshooting." >> $script_log
exit
fi

# check if $state contains any calls that passed the criteria for the query
if [[ $(wc -l < "$state") -ge 3  ]];then
echo "$timestamp -(EVENT)	$node has found talkgroup call(s) exceeding $duration_limit seconds" >> $script_log
echo "$timestamp -(INFO)	Targeted talkgroups are in data/talkgroups.txt." >> $script_log
echo "$(sed '1,2d' $state | awk '{print $1}')" > $formatter_in
python $py_formatter $main_dir
rm -f $formatter_in
fi

# this checks if there are long calls from targeted talkgroups. Delete, no email.
if test -f "$auto_del"; then
	echo "$timestamp -(DELETE)	Long duration calls from targeted talkgroup exceeding $duration_limit seconds found. Preparing to send delete command." >> $script_log
	to_del=$(cat $auto_del)
	delete="mysql -u[REDACTED] -p$key scu -e 'set @currTime = CURRENT_TIMESTAMP(); DELETE FROM PTT_AS_CALL WHERE CALL_TYPE != 5 AND PTT_CALL_ID in ($to_del) AND TIME_TO_SEC(timediff(@currTime,START_TIME)) > $duration_limit;'"
	ssh -t si@"$node" "$delete"
	echo "$timestamp -(INFO)	Long duration call(s) $to_del delete command sent successfully." >> $script_log
	ssh -t si@"$node" "echo '$auto_del_cont' | mailx -r '$sender'  -s '$auto_del_subj' -c '${v_CC}' -b '${v_BCC}' '${v_To}'" </dev/null
	rm -f $main_dir/data/auto_del.tmp
	else
	echo "$timestamp -(OK)	No long duration call(s) from targeted talkgroups found." >> $script_log
fi

# this checks if there are long calls from other talkgroups. No delete, just send email.
if test -f "$no_del"; then
	echo "$timestamp -(ALERT)	Long duration calls from non-targeted talkgroup exceeding $duration_limit seconds found. Preparing to send alert for NOC." >> $script_log
	to_alert=$(cat $no_del)
	ssh -t si@"$node" "echo '$no_del_cont' | mailx -r '$sender'  -s '$no_del_subj' -c '${v_CC}' -b '${v_BCC}' '${v_To}'" </dev/null
	echo "$timestamp -(INFO)	Alert for long duration call(s) $to_alert sent successfully." >> $script_log
	rm -f $main_dir/data/no_del.tmp
	else
	echo "$timestamp -(OK)	No long duration call(s) from non-targeted talkgroups found." >> $script_log
fi
