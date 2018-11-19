#!/bin/bash
# set up svn repo permissions
REPONAME=$1
USAGE=" USAGE: ${0} <new repository name>"

if [[ $REPONAME == "" ]] ; then
   echo "    ERROR"
   echo $USAGE
   echo ""
   exit 1
elif [[ -e $REPONAME ]] ; then
   echo "    ERROR"
   echo " $REPONAME exists!"
   exit 1
fi

echo ""
echo " Setting up $REPONAME ...."

#svnadmin create $REPONAME

cd $REPONAME
THISPATH=`pwd`
THISDIR=`basename $THISPATH`
echo $THISPATH $THISDIR

if [[ $REPONAME != $THISDIR ]] ; then
   echo "    ERROR"
   echo " Bad directory!"
   exit 1
fi

chmod 775 db
chgrp -R cvs db
chmod 775 db/txn-current
chmod 775 db/txn-current-lock
chmod 775 db/transactions
chmod 775 db/txn-protorevs
chmod 664 db/write-lock
chmod 775 db/revs/0
chmod 775 db/revprops
chmod 775 db/revprops/0

cd ..

echo ""
echo " If you got this far without errors,"
echo " you can now go to your remote PC and
echo " setup trunk and tags dirs."
echo ""


