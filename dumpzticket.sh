#!/bin/sh
# This script dumps the  zticket database to a standard MySQL dump file
# For instructions see HowToManageMySql.txt in the znyx CVS project
#
mysqldump --password='indian48' zticket > /usr/local/web/ztts/zticket.dmp
cp /usr/local/web/ztts/zticket.dmp /tmp/
cd /tmp
tar cvzf  zticket.dmp.zbackups.tgz zticket.dmp

