#!/bin/sh
# This script dumps the bugs database to a standard MySQL dump file
# For instructions see HowToManageMySql.txt in the znyx CVS project
#
# added a tarball and copy so that ftp_backup.pl will pickup the tarball
# and send to liberace every night
mysqldump --password='indian48' redmine > /var/lib/mysql/redminedumpfile
mysqldump --password='indian48' redmine_development > /var/lib/mysql/redmine_dev_dumpfile
mysqldump --password='indian48' redmine_test > /var/lib/mysql/redmine_test_dumpfile
tar cvzf /tmp/redminedumpfile.zbackups.tgz /var/lib/mysql/redminedumpfile

