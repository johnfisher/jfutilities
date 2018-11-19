#!/bin/bash

md5sum testsrc/* > goodsum
rm -f testdest/*
count=0

while [ "$count" -le 100000 ]
do
        cp testsrc/* testdest/
        ls -l testsrc/*
        rm -f testsrc/*
        cp testdest/* testsrc/
#       rm -f testdest/*
        let "count+=1"
        echo "COUNT = $count ......\n"
done
md5sum testdest/* > lastsum
echo "\n All Done ............\n"
diff goodsum lastsum
