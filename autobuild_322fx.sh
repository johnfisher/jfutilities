#!/bin/bash
# script to nightly build via script
# depends on perl script to 
# kick off this script
# send notification
# ftp products over to release server
## runs from the chrooted build area only!

# fiddle enviro - definitive settings not known
# this set works, based on the build user
export PATH=/zbin:.:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/X11R6/bin:${PATH}
export CVSROOT=:pserver:jfisher@pt:/usr/local/cvs
export BASH=/bin/bash
export BASH_VERSION='2.03.0(1)-release'
export DIRSTACK=()
export EDITOR=vi
export HOME=/root
export HOSTNAME=liberace
export HOSTTYPE=powerpc
export LOGNAME=root
export MAIL=/var/mail/build
export MAILCHECK=60
export OSTYPE=linux-gnu
export PIPESTATUS=([0]="0")
export SHELL=/bin/bash
export SUDO_COMMAND='/usr/sbin/chroot buildenv/potato /root/.start'
export SUDO_GID=1013
export SUDO_UID=1013
export SUDO_USER=build
export USER=root

# valid buildno's are 6150 ...
BUILDNO=$1

DATE=`date`
SHORTDATE=`date +%D`
set -- `date`
DAY=$1

# clean up and prepare
cd /builds/autobuild/$DAY/$BUILDNO
rm -rf 322fx 

 
 # do the 322f branch ....
 # checkout fresh tree and make its own dir
 
 cvs co -r RDR3_2_2fbranch+off-RDR322f rdr
 mv rdr 322fx
 cd 322fx
 
# rewrite version file  usual version = "OpenArchitect Version 3.2.2 build m"
# the prompt is taken from the 3rd and fifth words of the line in the version
# file thats contains "version" no case required
#
echo "" > prebuilt/etc/version
echo "OpenArchitect Version 3.3  build  $SHORTDATE" >> prebuilt/etc/version
echo  "CVS Branch: branch 3.2.2f tip" >> prebuilt/etc/version
echo  "CVS Tag: RDR3_2_2fbranch+off-RDR322f  nightly build" >> prebuilt/etc/version
  echo $DATE >> prebuilt/etc/version
  echo "" >> prebuilt/etc/version
  
  # build the tree
 make build_$BUILDNO > build.log  2>&1
 
 # at this point go away. the perl script will find the file and ftp it...
 
 
      
