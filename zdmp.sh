#! /bin/bash
#
## #########################################################################
##
##  (c) Copyright 2006 ZNYX Corporation
##  All Rights Reserved.
##
## #########################################################################
##
##  This program is free software; you can redistribute it and/or modify
##  it under the terms of the GNU General Public License as published by
##  the Free Software Foundation; either version 2 of the License, or
##  (at your option) any later version.
##
##  This program is distributed in the hope that it will be useful,
##  but WITHOUT ANY WARRANTY; without even the implied warranty of
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##  GNU General Public License for more details.
##
## #########################################################################
#
# Dump a block of kernel virtual memory
#
# Command line parameters;
#   -h hostname	Optional
#   start_addr	First word to dump - kernel memory starts at 0xC0000000
#   num		Number of bytes to dump


# ##########################################################################
# To dump a remote host by default, fill in host address and uncomment
# the following line. 
#
# host_parm="-h 100.30"
#
# Note:	 If specify -h command line option, will override the default host
# address.  If want to look at local memory, need to recomment the above line.
# ##########################################################################


wrds_per_ln=4			# how many words dumped per line of output

usage() {
	printf "Usage: $0 [-h hostname] starting_addr number_of_bytes\n"
	exit
}

# Pick up parameters
if [ x$1 = x-h ] ; then		# Check for optional "-h hostname"
	if [ -z $2 ] ; then
	printf "Missing hostname\n"
	usage
	fi
	host_parm="-h $2"
	shift
	shift
fi

if [ -z $1 ] ; then
	printf "Missing required starting address\n"
	usage
fi
if [ -z $2 ] ; then
	printf "Missing required byte count\n"
	usage
fi

let start_addr=$1
let num=$2

# sanity check the starting address
let tmp="$start_addr & 3"
if [ $tmp -ne 0 ] ; then
	printf "Starting address must be on word boundary; is 0x%X\n" \
		$start_addr
	exit
fi

# loop reading word at a time

count=0
ln_cnt=0
let end_of_ln=$wrds_per_ln-1
let addr=$start_addr

while [ $count -lt $num ] ; do
	# calc next address
	addr=`printf "0x%X" $addr`

	# if we're at a new line, print address
	let tmp=$ln_cnt%$wrds_per_ln
	if [ $tmp -eq 0 ] ; then
		printf "0x%08X: " $addr
	fi

	zreg $host_parm $addr	# really access memory
	if [ $tmp -eq $end_of_ln ] ; then
		printf "\n"
	else
		printf " "
	fi

	let count=$count+4
	let addr=$addr+4
	let ln_cnt=$ln_cnt+1
done

if [ $tmp -ne $end_of_ln ] ; then
	printf "\n"
fi
