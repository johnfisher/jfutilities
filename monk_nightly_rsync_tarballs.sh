#!/bin/bash
# rsynch file to run from cron on monk every night
# rsyncs from sshfs mounted drive attached to pt
# rsyncs cvs repository to a local directory and 
# then rysncs it off to Fremont, so its saved locally and remotely

# --bwlimit=KBPS rsync parameter
THROTTLE=  #--bwlimit=500
OFFBACK=/data/offsite_backup_fremont
FREMONT=john.fisher@10.1.1.40:/mnt/vg2/volume2/BACKUPS2/SANTABARBARA/MONK
DATE=`date`
set -- `date`
DAYOFWEEK=$1
DAYOFMONTH=$3

# rsync from the network share to another disk on this host
# this saves a hard copy locally
rsync -avz root@pt.sb.znyx.com:/usr/local/cvs  $OFFBACK/
rsync -avz root@pt.sb.znyx.com:/var/svn  $OFFBACK/
rsync -avz root@pt.sb.znyx.com:/var/git   $OFFBACK/
rsync -avz root@diz.sb.znyx.com:/zbackups_outgoing/*  $OFFBACK/diz


# now make another rysnc to Brett's openfiler up in Fremont.
rsync -avz $THROTTLE $OFFBACK/cvs $FREMONT/Backups
rsync -avz $THROTTLE $OFFBACK/svn $FREMONT/Backups
rsync -avz $THROTTLE $OFFBACK/git $FREMONT/Backups
rsync -avz $THROTTLE $OFFBACK/diz $FREMONT/Backups
rsync -avz $OFFBACK/manual  $FREMONT/manual_backups

rm -rf /data/cvs_tarballs_by_dayofweek/$DAYOFWEEK
mkdir /data/cvs_tarballs_by_dayofweek/$DAYOFWEEK
rm -rf /data/svn_tarballs_by_dayofweek/$DAYOFWEEK
mkdir /data/svn_tarballs_by_dayofweek/$DAYOFWEEK
rm -rf /data/git_tarballs_by_dayofweek/$DAYOFWEEK
mkdir /data/git_tarballs_by_dayofweek/$DAYOFWEEK
rm -rf /data/diz/$DAYOFWEEK
mkdir /data/diz/$DAYOFWEEK

       for DIR in `find $OFFBACK/cvs   -maxdepth 1 -type d -printf '%f\n' `
                do
                        # have to eliminate topmost dir which is a quirk of find command,
                        # it lets  through the parent dir to the list... also /released is just too big
                        if [[ $DIR  != "cvs" && $DIR != "released" ]]  ; then
                                tar cvzf /data/cvs_tarballs_by_dayofweek/$DAYOFWEEK/$DIR.tgz $OFFBACK/cvs/$DIR
                        fi
                done

        for DIR in `find $OFFBACK/svn   -maxdepth 1 -type d -printf '%f\n' `
                do
                        # have to eliminate topmost dir which is a quirk of find command,
                        # it lets  through the parent dir to the list...
                        if [ $DIR  != "svn" ]  ; then
                                tar cvzf /data/svn_tarballs_by_dayofweek/$DAYOFWEEK/$DIR.tgz $OFFBACK/svn/$DIR
                        fi
                done

        for DIR in `find $OFFBACK/git   -maxdepth 1 -type d -printf '%f\n' `
                do
                        # have to eliminate topmost dir which is a quirk of find command,
                        # it lets  through the parent dir to the list...
                        if [ $DIR  != "git" ]  ; then
                                tar cvzf /data/git_tarballs_by_dayofweek/$DAYOFWEEK/$DIR.tgz $OFFBACK/git/$DIR
                        fi

                done

	for DIR in `find /data/offsite_backup_fremont/diz  -maxdepth 1 -type d -printf '%f\n' `

				do

    tar cvzf /data/diz/$DAYOFWEEK/$DIR.tgz /data/offsite_backup_fremont/diz

				done



exit 1    

