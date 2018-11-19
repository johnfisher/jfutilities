#!/bin/sh
# pt backup script for ZNYX Networks
#
# Tape Backup for SBO office
#
# USAGE thursday_bk.sh "/usr/local"
#
# ARCHIVING:
# run mt - f /dev/tape rewind before most commands
# tar cvzf /dev/tape <filespec> does a simple dump
#  tar cvzf /dev/tape -g <snapshot record file name> <filespec> does an incremental
#
# RESTORING:
# tar xvzf /dev/tape <filespec to restore> <path to restore to>
#
# LOGGING
# logs are in /var/log/backup/ kept one per weekday, overwritten each time
#
# install this script in /usr/sbin on pt
#
#
mt -f /dev/tape rewind
sleep 60
BK=$1
cd $BK
echo " " > /var/log/backup/thursday.log
DATE=`date`  
echo "Starting backup of  -full thursday tape at $DATE " >> /var/log/backup/thursday.log
tar cvzf /dev/tape  * >>/var/log/backup/thursday.log
echo " " >> /var/log/backup/thursday.log

DATE=`date` 
 echo "Backed up -full thursday tape on  $DATE ">> /var/log/backup/thursday.log

mt -f /dev/tape rewind
sleep 1000
mt -f /dev/tape offline 
