#!/bin/sh
# script to backup all databases on cvs-jf
#
cd /var/lib/mysql
tar cvzf /home/jfisher/db.tgz *

