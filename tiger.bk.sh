#!/bin/sh
# script to backup user files on server tiger 
#
DATE=`date`
LOG=/var/log/backup.log

#### overwrites log every day
echo "Starting tarballs at $DATE...." > $LOG

cd /home/mike/potato/usr
tar cvzf /tmp/mike.tiger.zbackup.tgz   src
DATE=`date`
echo " " >> $LOG
echo "*************** Mike's Backup ****************" >> $LOG
echo " " >> $LOG
echo "/home/swall/potato/usr/src backed up on $DATE" >> $LOG
echo " " >> $LOG
echo "**********************************************" >> $LOG


cd /home/kathy/potato/
tar cvzf /tmp/kathy.tiger.zbackup.tgz   src
DATE=`date`
echo " " >> $LOG
echo "*************** Kathy's Backup ****************" >> $LOG
echo " " >> $LOG
echo "/home/kathy/potato/src backed up on $DATE" >> $LOG
echo " " >> $LOG
echo "**********************************************" >> $LOG

cd /home/bobm/potato/usr
tar cvzf /tmp/bobm.tiger.zbackup.tgz   src
DATE=`date`
echo " " >> $LOG
echo "*************** BobM's Backup ****************" >> $LOG
echo " " >> $LOG
echo "/home/bobm/potato/usr/src backed up on $DATE" >> $LOG
echo " " >> $LOG
echo "**********************************************" >> $LOG

#cd /home/jochen/potato/
#tar cvzf /tmp/jochen.tiger.zbackup.tgz   build
#DATE=`date`
#echo " " >> $LOG
#echo "*************** Jochen's Backup ****************" >> $LOG
#echo " " >> $LOG
#echo "/home/jochen/potato/build backed up on $DATE" >> $LOG
#echo " " >> $LOG
#echo "**********************************************" >> $LOG



#cd /home/trudy/potato/usr
#tar cvzf /tmp/trudy.tiger.zbackup.tgz   src
#DATE=`date`
#echo " " >> $LOG
#echo "*************** Trudy's Backup ****************" >> $LOG
#echo " " >> $LOG
#echo "/home/trudy/potato/usr/src backed up on $DATE" >> $LOG
#echo " " >> $LOG
#echo "**********************************************" >> $LOG

