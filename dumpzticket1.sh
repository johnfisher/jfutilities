#!/bin/sh
# This script dumps the development zticket1 database to a standard MySQL dump file
# For instructions see HowToManageMySql.txt in the znyx CVS project
#
mysqldump --password='indian48' zticket1 > /var/lib/mysql/zticket1dumpfile

