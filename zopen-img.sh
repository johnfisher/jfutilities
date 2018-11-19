#!/bin/bash
# Znyx Networks
#  zopen-img.sh
#  opens disk images and mounts them
#  for testing

IMAGE=$1
NBD=/dev/nbd4
MNPOINT=/tmp/nbd

# error-checking for root
if [ `whoami` != "root" ]; then
	echo "ERROR:  root is required for this script. Exiting..."
	exit
fi
# general error checking
if [ ! -e $IMAGE ]; then
	echo ""
	echo " Bad image parameter $IMAGE."
	echo " exiting...."
fi
# compressed file error checking
if [ ! -e $image ]; then
	echo ""
	echo " Bad image parameter $IMAGE."
	echo " exiting...."
fi


# cleanup just in case
qemu-nbd -d $NBD

# open the image
qemu-nbd -n -t -c $NBD $IMAGE  

mkdir -p $MNPOINT
mount $NBD $MNPOINT

