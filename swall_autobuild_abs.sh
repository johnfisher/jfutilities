#!/bin/bash
# script to nightly build via script
# depends on perl script to 
# kick off this script
# send notification
# ftp products over to release server
## runs from the chrooted build area only!



# valid buildno's are 4900 4920 5000 6000 sundgs 7100 7200base 7200fab....
BUILDNO=$1

DATE=`date`
SHORTDATE=`date +%D`
set -- `date`
DAY=$1

# clean up and prepare
cd /builds/autobuild/$DAY/$BUILDNO
rm -rf abs rdr 

 
 # do the abstract branch ....
 # checkout fresh tree and make its own dir
 
 cvs co -r RDRABSTRACTbranch+off-RDR2_2_0a rdr
 mv rdr abs
 cd abs
 
 # rewrite version file  usual version = "OpenArchitect Version 3.2.2 build m"
# the prompt is taken from the 3rd and fifth words of the line in the version
# file thats contains "version" no case required
#
echo "" > prebuilt/etc/version
echo "###Steve###  OpenArchitect Version 3.3  build  $SHORTDATE" >> prebuilt/etc/version
echo  "CVS Branch: abstract tip 3.3" >> prebuilt/etc/version
echo  "CVS Tag: RDRABSTRACTbranch+off-RDR2_2_0a  nightly build" >> prebuilt/etc/version
  echo $DATE >> prebuilt/etc/version
  echo "" >> prebuilt/etc/version
  
  # build the tree
 make build_$BUILDNO > build.log  2>&1
 
 # at this point go away. the perl script will find the file and ftp it...
 
 
      
