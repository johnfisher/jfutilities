#!/bin/sh
# cvsrmdir.sh
# removes a tree of from cvs including all dirctories and files
#
# CVS rules on removing files and directories:
#     Fogel book:"Here is what you can do to remove a file from a module, but remain able to retrieve old revisions: 
#     Make sure that you have not made any uncommitted modifications to the file. 
#     If you remove the file without committing your changes, you will of course not be able to retrieve the file as it was 
#     immediately before you deleted it. 
#     Remove the file from your working copy of the module. You can for instance use rm. 
#     Use `cvs remove filename' to tell CVS that you really want to delete the file. 
#     Use `cvs commit filename' to actually perform the removal of the file from the repository"
#     
# removing a directory is just the opposite, first cvs remove, then rm
#

# usage check
if [ $# -ne 1 ]; then
	echo "Usage: only accepts one target directory to remove:" 1>&2
	exit 1
fi

# parameter
TARGET=$1

# make sure up-to-date
#cvs up -d -A $1

# get list of files
find ./$1 -type f | grep -v CVS > filelist
echo "++++++++++++++ got files \n"
cat filelist

# get list of dirs
find ./$1 -type d | grep -v CVS  > dirlist
echo "++++++++++++++ got dirs \n"
cat dirlist

# now separate the directories out of filelist
# CVS needs to handle them differently

exec 3<filelist
	while read LINE 0<&3
		do 
		if grep '$LINE' dirlist; then
			echo " ignoring grep '$LINE' dirlist \n "
		else
			echo "$LINE" >> myfiles
		fi
		done
exec 3<&-
cat myfiles

# first rm the files
# open file; read each line & remove it
exec 3<myfiles
	while read LINE 0<&3
		do 
		#rm -rf $LINE
		echo " would be removing $LINE "
		done
exec 3<&-
echo "++++++++++++++ rm'd the files \n"

# open file; read each line & remove it
exec 3<myfiles
	while read LINE 0<&3
		do 
		#cvs remove $LINE
		#sleep 2
		echo " would be removing $LINE"
		done
exec 3<&-
echo "++++++++++++++ cvs removed the files \n"
# commit changes
#cvs ci -m "removed by script" $1
echo "++++++++++++++ cvs committed changes to files \n"

# open file; read each line and remove
exec 3<dirlist
	while read LINE 0<&3
		do 
		#cvs remove $LINE
		#sleep 2
		echo " would be ceevees removing $LINE \n"
		done
exec 3<&-
echo "++++++++++++++ cvs removed the sub-dirs \n"

# now cvs remove the subdirectories
#cvs remove $1
echo "++++++++++++++ cvs remove $1 \n"

# finally we can rm the target directory and all left-over contents like CVS subdirectories
rm -rf $1

# clean up
#rm -rf filelist dirlist myfiles

echo "++++++++++++++ All Done!++++++++++\n \n"