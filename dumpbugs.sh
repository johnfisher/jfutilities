#!/bin/sh
# This script dumps the bugs database to a standard MySQL dump file
# For instructions see HowToManageMySql.txt in the znyx CVS project
#
# added a tarball and copy so that ftp_backup.pl will pickup the tarball
# and send to liberace every night
mysqldump --password='indian48' bugs > /var/lib/mysql/bugsdumpfile
tar cvzf /tmp/bugsdumpfile.zbackups.tgz /var/lib/mysql/bugsdumpfile

