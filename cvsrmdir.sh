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
cvs up -d -P $TARGET


# get list of files
find ./$TARGET -type f | grep -v CVS > filelist
echo "++++++++++++++ got files \n"

# get list of dirs
find ./$TARGET -type d | grep -v CVS  > dirlist
echo "++++++++++++++ got dirs \n"


# now separate the directories out of filelist
# CVS needs to handle them differently
echo "" > myfiles
exec 3<filelist
	while read LINE 0<&3
		do 
		if grep '$LINE' dirlist; then
			echo " ignoring $LINE \n "
		else
			echo ". "
			echo "$LINE" >> myfiles
		fi
		done
exec 3<&-


# first rm the files
# open file; read each line & remove it
exec 3<myfiles
	while read LINE 0<&3
		do 
			rm -rf $LINE
			echo "FILES-- deleting $LINE "
		done
exec 3<&-
echo "++++++++++++++ rm'd the files \n"

# open file; read each line & remove it
exec 3<myfiles
	while read LINE 0<&3
		do 
			cvs remove $LINE 2>/dev/null
			echo "FILES-- CVS removing $LINE"
			sleep 2
		done
exec 3<&-
echo "++++++++++++++ cvs removed the files \n"
# commit changes
cd $TARGET ; cvs ci -m "removed by script" ; cd ..
echo "++++++++++++++ cvs committed changes to files \n"

# remove all the subdirectories
# open file; read each line and remove
exec 3<dirlist
	while read LINE 0<&3
		do 
			cvs remove $LINE 2>/dev/null
			echo "DIRS-- CVS removing $LINE"
			sleep 2
		done
exec 3<&-
echo "++++++++++++++ cvs removed the sub-dirs \n"

# now cvs remove the directory
cd $TARGET ; mv CVS ../xxx ; rm -rf * ; mv ../xxx CVS ; cd ..
cvs remove $TARGET
echo "++++++++++++++ cvs remove $TARGET \n"

# finally we can rm the target directory 
rm -rf $TARGET

# clean up
rm -rf filelist dirlist myfiles

echo "++++++++++++++ All Done!++++++++++\n \n"