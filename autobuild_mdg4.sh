#!/bin/bash
# script to nightly build via script SUNDGS ONLY
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

# valid buildno's are mdg4....
BUILDNO=`$1`
DATE=`date`
set -- `date`
DAY=$1

# clean up and prepare
cd /builds/autobuild/$DAY/4920
rm -rf mdg4

# checkout fresh tree and make its own dir

cvs co -r  RDR3_2_1branch+off-RDR321q rdr
mv rdr mdg4  
cd  mdg4

# rewrite version file
echo "" > prebuilt/etc/version
 echo "OpenArchitect Branch: mdg4.3.2.1tx  MDG4 Tag: RDR3_2_1branch+off-RDR321q  nightly build" >> prebuilt/etc/version
 echo $DATE >> prebuilt/etc/version
 echo "Packaging Copyright (C) 2004 Znyx Networks, Inc." >> prebuilt/etc/version
 echo "" >> prebuilt/etc/version
 
 # build the tree
 make build_4920 >> build.log
 
 
 
 # at this point go away. the perl script will find the file and ftp it...
 
 
      
