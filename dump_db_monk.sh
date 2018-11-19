#!/bin/sh
# This script dumps the important databases on server monk to a standard MySQL dump file
# For instructions see HowToManageMySql.txt in the znyx CVS project
#
#  ftp_backup.pl will pickup the tarball
#
mysqldump --password='indian48' zticket > /var/lib/mysql/zticketdumpfile
mysqldump --password='indian48' mysql > /var/lib/mysql/mysqldumpfile
tar cvzf /zbackups_outgoing/monk.zticket.dmp.remote.zbackup.tgz /var/lib/mysql/zticketdumpfile
tar cvzf/zbackups_outgoing/monk.mysql.dmp.remote.zbackup.tgz /var/lib/mysql/mysqldumpfile
tar cvzf /zbackups_outgoing/monk.mysql_whole_dbs_notdmp.remote.zbackup.tgz /var/lib/mysql


