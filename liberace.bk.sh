#!/bin/sh
# script to backup user files on server liberace 
#
########## OUT OF DATE ##############

DATE=`date`
LOG=/var/log/backup.log
#### overwrites log every day
echo " Starting tarballs at $DATE...." > $LOG

cd /home/swall/potato/usr
tar cvzf /tmp/steve.liberace.zbackup.tgz   src
DATE=`date`
echo " " >> $LOG
echo "*************** Steve's Backup ****************" >> $LOG
echo " " >> $LOG
echo "/home/swall/potato/usr/src backed up on $DATE" >> $LOG
echo " " >> $LOG
echo "**********************************************" >> $LOG


#cd /home/djonathan/potato
#tar cvzf /tmp/david.liberace.zbackup.tgz   root
#DATE=`date`
#echo " " >> $LOG
#echo "*************** David's Backup ****************" >> $LOG
#echo " " >> $LOG
#echo "/home/djonathan/potato/root backed up on $DATE" >> $LOG
#echo " " >> $LOG
#echo "**********************************************" >> $LOG

cd /home/dweaver/
tar cvzf /tmp/dweaver.liberace.zbackup.tgz   *
DATE=`date`
echo " " >> $LOG
echo "*************** DWeaver's Backup ****************" >> $LOG
echo " " >> $LOG
echo "/home/dweaver/* backed up on $DATE" >> $LOG
echo " " >> $LOG
echo "**********************************************" >> $LOG

cd /home/cpage/potato
tar cvzf /tmp/chad.liberace.zbackup.tgz   root
DATE=`date`
echo " " >> $LOG
echo "*************** Chad's Backup ****************" >> $LOG
echo " " >> $LOG
echo "/home/cpage/potato/root backed up on $DATE" >> $LOG
echo " " >> $LOG
echo "**********************************************" >> $LOG