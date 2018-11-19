#!/bin/bash
# rsynch file to run from cron
# should be run on each month, pick a day number and set it in cron
# i.e. run very 15th of a month
# will save a monthly archive for12 months and then rotate


DATE=`date`
set -- `date`
MONTH=$2


cd /data/outgoing_nightly_backups

rsync -avz -e --bwlimit256 "ssh -i /root/.ssh/monk-rsync-key" *  root@hawk.znyx.com:/home/zbackup/nightly_backups/$2

