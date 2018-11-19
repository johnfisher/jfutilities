#!/bin/bash
# script to record du output on use of disk space
# enhancement to diskfree emailer script 


DATE=`date`
SHORTDATE=`date +%m%e%Y`
set -- `date`
DAY=$1

# clean up and prepare
cd /tmp
du -h --max-depth 1 / > total_diskusage_$DAY.txt
du -h --max-depth 1 /home > user_diskusage_$DAY.txt
 

 
 
      
