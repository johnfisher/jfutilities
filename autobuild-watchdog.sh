#!/bin/bash
# starts watchdog for the nightly build script, autobuild.pl
# run from /etc/rcS.d linked to /etc/init.d linked to /zbin/autobuild-watchdog.sh
# set integer to hour you wish it to check
# it retries every 15 minutes 24 hours a day
# run in background like this: /zbin/autobuild_watchdog.pl 16 &
/zbin/autobuild_watchdog.pl 16 &

