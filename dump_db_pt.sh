#!/bin/sh
# This script dumps the important databases on server pt to a standard MySQL dump file
# For instructions see HowToManageMySql.txt in the znyx CVS project
#
# added a tarball and copy so that ftp_backup.pl will pickup the tarball
# and send to liberace every night
mysqldump --password='indian48' bugs > /var/lib/mysql/bugsdumpfile
mysqldump --password='indian48' mysql > /var/lib/mysql/mysqldumpfile
tar cvzf /zbackups_outgoing/pt.bugs.dmp.zbackup.tgz /var/lib/mysql/bugsdumpfile
tar cvzf /zbackups_outgoing/pt.mysql.dmp.zbackup.tgz /var/lib/mysql/mysqldumpfile
tar cvzf /zbackups_outgoing/pt.mysql_whole_dbs_notdmp.zbackup.tgz /var/lib/mysql


