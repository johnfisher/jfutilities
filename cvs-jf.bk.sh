#!/bin/sh
# script to backup user files on server cvs-jf
#
DATE=`date`
LOG=/var/log/backup.log

#### overwrites log every day
echo "Starting tarballs at $DATE...." > $LOG

cd /data
tar cvzf /tmp/work.cvs-jf.zbackup.tgz   work
DATE=`date`
echo " " >> $LOG
echo "*************** cvs-jf's work Backup ****************" >> $LOG
echo " " >> $LOG
echo "/data/work backed up on $DATE" >> $LOG
echo " " >> $LOG
echo "**********************************************" >> $LOG

cd /data
tar cvzf /tmp/work.cvs-jf.zbackup.tgz   web
DATE=`date`
echo " " >> $LOG
echo "*************** cvs-jf's web Backup ****************" >> $LOG
echo " " >> $LOG
echo "/data/web backed up on $DATE" >> $LOG
echo " " >> $LOG
echo "**********************************************" >> $LOG
