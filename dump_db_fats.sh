#!/bin/sh
# This script dumps the important databases on server diz to a standard MySQL dump file
# For instructions see HowToManageMySql.txt in the znyx CVS project
#
#  ftp_backup.pl will pickup the tarball 
#
mysqldump --password='indian48' oaflow_wp251 > /var/lib/mysql/fats-oaflowdemo_dumpfile
cp /var/lib/mysql/fats-oaflowdemo_dumpfile /var/www/oaflowdemo/oaflowdemo-database.dmp
mysqldump --password='indian48' mysql > /var/lib/mysql/mysqldumpfile

tar cvzf /zbackups_outgoing/fats.oaflowdemo.dmp.remote.zbackup.tgz /var/lib/mysql/fats-oaflowdemo_dumpfile
tar cvzf /zbackups_outgoing/fats.mysql.dmp.remote.zbackup.tgz /var/lib/mysql/mysqldumpfile
tar cvzf /zbackups_outgoing/fats.mysql_whole_dbs_notdmp.remote.zbackup.tgz /var/lib/mysql

cd /var/www/oaflowdemo ; cvs ci -m "nightly checkin" oaflowdemo-database.dmp




