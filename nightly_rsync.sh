#!/bin/bash
# rsynch file to run from cron

##############################################################
# temp to allow slow initialization of remote archive because the
# connection is so slow we cant start an rsync archive in
# 8 nightime hours...
#cd /data/outgoing_nightly_backups
# copy a* c* d* only to remote machine
#rm -rf b* j* k* s* m*
# copy b* to remote machine and incremental a* c* d*
#rm -rf j* k* s* m*
# copy j* k*  to remote machine and incremental a* c * d* b*
#rm -rf  s* m*
###############################################################

DATE=`date`
set -- `date`
DAY=$1
echo " Nightly Rsync started at $DATE " > /tmp/nightly_rsync.log
cd /data/outgoing_nightly_backups

rsync --bwlimit=256 -avz -e  "ssh -i /root/.ssh/monk-rsync-key" *  root@hawk.znyx.com:/home/zbackup/nightly_backups/$DAY

DATE=`date`
echo " Nightly Rsync finished at $DATE " >> /tmp/nightly_rsync.log

