#!/bin/bash
#Going to be using this with the 3.4.0c x86branch update:  this script md5sum's only text and executable files.

for i in `find`; do
        file $i | egrep "text" > /dev/null 2> /dev/null
        if [ $? -eq "0" ]; then md5sum $i; fi

        file $i | egrep "ELF" > /dev/null 2> /dev/null
        if [ $? -eq "0" ]; then echo `(objdump -S $i 2> /dev/null | md5sum)` $i; fi
done