#!/bin/bash
# rsynch file to run from cron
# should be run on each Friday only
# will save a weekly a archive for 4 or 5 weeks and then rotate


DATE=`date`
set -- `date`
DAYNO=$3


cd /data/outgoing_nightly_backups

if [  $DAYNO -le 7 ]
 then
	rsync -avz -e --bwlimit256 "ssh -i /root/.ssh/monk-rsync-key" *  root@hawk.znyx.com:/home/zbackup/nightly_backups/1fri

elif  [ "$DAYNO" -gt 7 ] && [ "$DAYNO" -le 14 ]  
 then
	rsync -avz -e --bwlimit256 "ssh -i /root/.ssh/monk-rsync-key" *  root@hawk.znyx.com:/home/zbackup/nightly_backups/2fri

elif [ $DAYNO -gt 14 ] &&  [ "$DAYNO" -le 21  ]
 then
	rsync -avz -e --bwlimit256 "ssh -i /root/.ssh/monk-rsync-key" *  root@hawk.znyx.com:/home/zbackup/nightly_backups/3fri

elif [ $DAYNO -gt 21 ] && [ "$DAYNO" -le 28  ]
 then
	rsync -avz -e --bwlimit256 "ssh -i /root/.ssh/monk-rsync-key" *  root@hawk.znyx.com:/home/zbackup/nightly_backups/4fri

elif [ $DAYNO -gt 28 ] && [ "$DAYNO" -le 31  ]
 then
	rsync -avz -e --bwlimit256 "ssh -i /root/.ssh/monk-rsync-key" *  root@hawk.znyx.com:/home/zbackup/nightly_backups/5fri

fi
