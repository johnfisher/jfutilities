#!/bin/bash
# rsynch file to run from cron on monk every night
# rsyncs from sshfs mounted drive attached to pt
# rsyncs cvs repository to a local directory and 
# then rysncs it off to Fremont, so its saved locally and remotely

# --bwlimit=KBPS rsync parameter
THROTTLE=--bwlimit=500
OFFBACK=/data/offsite_backup_fremont
FREMONT=john.fisher@10.1.1.40:/mnt/vg2/volume2/BACKUPS2/SANTABARBARA/MONK

# rsync from the network share to another disk on this host
# this saves a hard copy locally
rsync -avz root@pt.sb.znyx.com:/usr/local/cvs  $OFFBACK/
rsync -avz root@pt.sb.znyx.com:/var/svn  $OFFBACK/
rsync -avz root@pt.sb.znyx.com:/var/git   $OFFBACK/
rsync -avz root@diz.sb.znyx.com:/zbackups_outgoing/*  $OFFBACK/diz


# now make another rysnc to Brett's openfiler up in Fremont.
rsync -avz $THROTTLE $OFFBACK/svn $FREMONT/Backups
rsync -avz $THROTTLE $OFFBACK/svn $FREMONT/Backups
rsync -avz $THROTTLE $OFFBACK/git $FREMONT/Backups
rsync -avz $THROTTLE $OFFBACK/diz $FREMONT/Backups
rsync -avz $OFFBACK/manual  $FREMONT/manual_backups
exit 1    

