#!/bin/sh
# script to search a path for multiple files
# run as 
# zlook.sh <target path> <inputfilename>  
# zlook.sh starts in <target path> and looks for a set of files listed in <inputfilename>

# check the intruder.log output for time stamps and other evidence
# THE OUTPUT FILE WILL HAVE FALSE POSITIVES
#

echo
echo Searching $1 for files listed in $2 
echo 
echo Watch for false positives			 
echo May take a while...
echo 
echo ..... In your input file list,                	..... 
echo ..... for very short filenames                	.....
echo ..... look for a file named "d" using "/d"    	.....
echo ..... this prevents multiple false positives. 	.....

TARGET=$1
INPUT=$2
LOG=./filelist.log
LINE=
# assumption: one big find is quicker than many
find $TARGET -name '*' -exec ls -l '{}' ';' > $LOG 
echo
echo Find complete, now grepping for files....
echo 

while read LINE
	do
	
	echo =======================================================
	echo Looking for $LINE in $TARGET....
	echo 
	grep "$LINE\$" $LOG
	echo ..........................................................................................-
	echo

	done <"$INPUT"

rm -rf $LOG
echo
echo .........
echo ...... 
echo ...
echo .
echo         ...Ending...




