#!/bin/sh
# This script dumps the important databases on server diz to a standard MySQL dump file
# For instructions see HowToManageMySql.txt in the znyx CVS project
#
#  ftp_backup.pl will pickup the tarball 
#
mysqldump --password='indian48' bugs > /var/lib/mysql/diz-bugs_dumpfile
mysqldump --password='indian48' mysql > /var/lib/mysql/mysqldumpfile
mysqldump --password='indian48' wp2x > /var/lib/mysql/diz-wp2x_dumpfile
tar cvzf /zbackups_outgoing/diz.wp2x.dmp.remote.zbackup.tgz /var/lib/mysql/diz-wp2x_dumpfile
tar cvzf /zbackups_outgoing/diz.bugs.dmp.remote.zbackup.tgz /var/lib/mysql/diz-bugs_dumpfile
tar cvzf/zbackups_outgoing/diz.mysql.dmp.remote.zbackup.tgz /var/lib/mysql/mysqldumpfile
tar cvzf /zbackups_outgoing/diz.mysql_whole_dbs_notdmp.remote.zbackup.tgz /var/lib/mysql


