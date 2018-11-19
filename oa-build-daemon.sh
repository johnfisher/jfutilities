
#!/bin/bash
# /zbin/oa-build-daemon.sh


# the interval in seconds everything will be checked by this daemon-like script.
# interval=0 will result in skipping it.
loopinterval=3590
longloopinterval=3700
# set to 59 minutes so it will always hit the hour once
# but wont start the build twice in the same 24 hr period

# the init.d script knows this path and kills based on it
#echo $$ > /var/run/oa-build-daemon.pid


pid_file=/var/run/oa-build.pid
echo $$ > $pid_file

if [ $1 ] ; then
	STARTHOUR=$1
else
	STARTHOUR=19
fi

while [ 1 ] ; do
	DAY=`date +%a`
	HOUR=`date +%H`
    TIME=`date`
	if [ $HOUR = $STARTHOUR ] ; then
		# run build script and make sure the next try is in the next hour
		mail -s " OA4 build daemon started at $TIME" john.fisher@znyx.com  
		bash -c /zbin/nightly-OA4-build.sh &
		sleep $longloopinterval
 
	else
		# run  again
		sleep $loopinterval   
	fi
done


exit 1



