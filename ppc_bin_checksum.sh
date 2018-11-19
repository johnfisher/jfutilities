#!/bin/sh
# Script by Chad
# Gets a true binary checksum of objects in OA PPC build without pesky timestamps
# The end result is an md5sum of the disassembled assembly code for each PPC binary found in dist


for i in `find dist`; do (file $i | grep PowerPC >> /tmp/files); done
for i in `cut -d : -f 1 /tmp/files`; do printf "%s %s\n" `objdump -S $i 2> /dev/null | md5sum` $i; done > output
