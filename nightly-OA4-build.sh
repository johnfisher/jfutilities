#!/bin/bash
# nightly build for cron job
# OA4
##############################
RECIPIENT=john.fisher@znyx.com
DATE=`date +%F`
DAY=`date +%a`
BHOME=/home/build

cd "$BHOME"

failmail () {
    cd "$BHOME"/oa
    SUB="OA4 build $1 on $DATE FAILED"
    cat build.steps > fail.log
    echo "" >> fail.log
    tail -200 build.log >>  fail.log
    /zbin/z-mail.py "$SUB" "build@10.2.1.27.znyx.com" "$RECIPIENT" "./fail.log"
}

 rm -rf bcm.yesterday  oa.yesterday
 mv oa oa.yesterday
 mv bcm bcm.yesterday
 # clean out todays dir early so we get the right
 # directory clean
 ssh -l root pt 'D=`date +%a` ; rm -f /ut/$D/oa4/* '
# 
 git clone root@pt:/var/git/bcm.git
 git clone root@pt:/var/git/oa.git

cd oa
# version has to start with a number
VERSION=`cat version | tr -d ' ' `
NVERSION=${VERSION}nightly-${DATE}


echo $NVERSION > version


 cd "$BHOME"/bcm
 BVERSION=`cat version | tr -d ' ' `
 BNVERSION=${BVERSION}nightly-${DATE}
 echo $BNVERSION > version

cd "$BHOME"/oa
BUILDTYPE=INTERNAL make nightly > build.log


if [[ ! `grep ".pkgs-built" build.steps` ]] ; then
   failmail pkgs-built
elif [[ ! `grep "bcm" build.steps` ]] ; then
   failmail bcm
elif [[ ! `grep "hv-9210" build.steps` ]] ; then
   failmail hv-9210
elif [[ ! `grep "hv-2040" build.steps` ]] ; then
   failmail hv-2040
elif [[ ! `grep "hv-8100" build.steps` ]] ; then
   failmail hv-8100
fi

cd "$BHOME"/oa/release

# for now test to see if any md5 file appeared
files=$(ls  *.md5  | wc -l)
if [[ "$files" -gt  0 ]] ; then
echo " copying to pt..."  
	# clean out todays dir
    ssh -l root pt 'D=`date +%a` ; rm -f /ut/$D/oa4/* '   
	# copy files
    scp * root@pt:/ut/${DAY}/oa4 
	# reset permissions
    ssh -l root pt 'chgrp -R cvs /ut/*/oa4 ; chown -R build /ut/*/oa4'   
else
    cd "$BHOME"/oa
    SUB="OA4 md5 build on $DATE FAILED"
    tail -200 build.log > fail.log
    /zbin/z-mail.py "$SUB" "build@10.2.1.27.znyx.com" "$RECIPIENT" "./fail.log"
fi


exit 1

