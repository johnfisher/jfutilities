#!/bin/sh
cd /zbin
cvs up -d -P
cd /home/build/buildenv/potato/zbin
cvs up -d -P
cd /released
cvs up -d -P

