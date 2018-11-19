#!/bin/bash
##################################################################
# ASSUMES that monk_nightly_rsync.sh has already run
# get day of week
# make fres directories by days name
# look in the rsynch'ed spopts for the fresh copies of the repos
# then tarball individual directories from the repos 
# 
##################################################################



DATE=`date`
set -- `date`
DAYOFWEEK=$1
DAYOFMONTH=$3


rm -rf /data/cvs_tarballs_by_dayofweek/$DAYOFWEEK
mkdir /data/cvs_tarballs_by_dayofweek/$DAYOFWEEK
rm -rf /data/svn_tarballs_by_dayofweek/$DAYOFWEEK
mkdir /data/svn_tarballs_by_dayofweek/$DAYOFWEEK
rm -rf /data/git_tarballs_by_dayofweek/$DAYOFWEEK
mkdir /data/git_tarballs_by_dayofweek/$DAYOFWEEK
rm -rf /data/diz/$DAYOFWEEK
mkdir /data/diz/$DAYOFWEEK

        for DIR in `find /pt.cvsrepos  -maxdepth 1 -type d -printf '%f\n' `              
                do
			# have to eliminate topmost dir which is a quirk of find command,
			# it lets  through the parent dir to the list... also /released is just too big
                        if [[ $DIR  != "pt.cvsrepos" && $DIR != "released" ]]  ; then
                        	tar cvzf /data/cvs_tarballs_by_dayofweek/$DAYOFWEEK/$DIR.tgz /pt.cvsrepos/$DIR
                        fi

                done
                
	for DIR in `find /pt.svnrepos  -maxdepth 1 -type d -printf '%f\n' `              
                do
			# have to eliminate topmost dir which is a quirk of find command,
			# it lets  through the parent dir to the list...
                        if [ $DIR  != "pt.svnrepos" ]  ; then
                        	tar cvzf /data/svn_tarballs_by_dayofweek/$DAYOFWEEK/$DIR.tgz /pt.svnrepos/$DIR
                        fi

                done

	for DIR in `find /pt.gitrepos  -maxdepth 1 -type d -printf '%f\n' `              
                do
			# have to eliminate topmost dir which is a quirk of find command,
			# it lets  through the parent dir to the list...
                        if [ $DIR  != "pt.gitrepos" ]  ; then
                        	tar cvzf /data/git_tarballs_by_dayofweek/$DAYOFWEEK/$DIR.tgz /pt.gitrepos/$DIR
                        fi

                done

	for DIR in `find /data/offsite_backup_fremont/diz  -maxdepth 1 -type d -printf '%f\n' `    

				do

    tar cvzf /data/diz/$DAYOFWEEK/$DIR.tgz /data/offsite_backup_fremont/diz

				done




exit 1    

