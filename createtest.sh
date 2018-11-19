#!/bin/sh
# createtest.sh  creates a tree of files for cvs testing
# remove the tree using cvsrmdir.sh
# call this with one dirname only

# usage check
if [ $# -ne 1 ]; then
	echo "Usage: only accepts one target directory to create:" 1>&2
	exit 1
fi

DIR=$1
DIR1=bag
DIR2=box
DIR10=parcel
DIR11=sack
DIR100=satchel
DIR101=gunny
DIR110=kerchief
DIR111=wrap
DIR112=sock
DIR20=bin
DIR21=crate


mkdir $DIR
cvs add $DIR
sleep 2
touch $DIR/fileA $DIR/fileB $DIR/fileC
cvs add $DIR/fileA $DIR/fileB $DIR/fileC
mkdir $DIR/$DIR1
cvs add $DIR/$DIR1
sleep 2
touch $DIR/$DIR1/file1 $DIR/$DIR1/file2
cvs add $DIR/$DIR1/file1 $DIR/$DIR1/file2
mkdir $DIR/$DIR1/$DIR10
cvs add $DIR/$DIR1/$DIR10
sleep 2
touch $DIR/$DIR1/$DIR10/file4 $DIR/$DIR1/$DIR10/file3
cvs add $DIR/$DIR1/$DIR10/file4 $DIR/$DIR1/$DIR10/file3
mkdir $DIR/$DIR1/$DIR10/$DIR100
mkdir $DIR/$DIR1/$DIR10/$DIR101
cvs add $DIR/$DIR1/$DIR10/$DIR100 $DIR/$DIR1/$DIR10/$DIR101
sleep 2
touch $DIR/$DIR1/$DIR10/$DIR100/file5 $DIR/$DIR1/$DIR10/$DIR101/file6
cvs add $DIR/$DIR1/$DIR10/$DIR100/file5 $DIR/$DIR1/$DIR10/$DIR101/file6
touch $DIR/$DIR1/$DIR10/$DIR100/file5a $DIR/$DIR1/$DIR10/$DIR101/file6a
cvs add $DIR/$DIR1/$DIR10/$DIR100/file5a $DIR/$DIR1/$DIR10/$DIR101/file6a
mkdir $DIR/$DIR1/$DIR11
cvs add $DIR/$DIR1/$DIR11
sleep 2
touch $DIR/$DIR1/$DIR11/file7
cvs add $DIR/$DIR1/$DIR11/file7
sleep 2
touch $DIR/$DIR1/$DIR11/file7a
cvs add $DIR/$DIR1/$DIR11/file7a
sleep 2
touch $DIR/$DIR1/$DIR11/file7b
cvs add $DIR/$DIR1/$DIR11/file7b
sleep 2
mkdir $DIR/$DIR1/$DIR11/$DIR110
mkdir $DIR/$DIR1/$DIR11/$DIR111
mkdir $DIR/$DIR1/$DIR11/$DIR112
cvs add $DIR/$DIR1/$DIR11/$DIR110 $DIR/$DIR1/$DIR11/$DIR111 $DIR/$DIR1/$DIR11/$DIR112
sleep 2
touch $DIR/$DIR1/$DIR11/$DIR110/file10 $DIR/$DIR1/$DIR11/$DIR111/file9 $DIR/$DIR1/$DIR11/$DIR112/file8
sleep 2
cvs add $DIR/$DIR1/$DIR11/$DIR110/file10 $DIR/$DIR1/$DIR11/$DIR111/file9 $DIR/$DIR1/$DIR11/$DIR112/file8
sleep 2
touch $DIR/$DIR1/$DIR11/$DIR110/file10a $DIR/$DIR1/$DIR11/$DIR111/file9a $DIR/$DIR1/$DIR11/$DIR112/file8a
sleep 2
cvs add $DIR/$DIR1/$DIR11/$DIR110/file10a $DIR/$DIR1/$DIR11/$DIR111/file9a $DIR/$DIR1/$DIR11/$DIR112/file8a
sleep 2
mkdir $DIR/$DIR2
cvs add $DIR/$DIR2
sleep 2
touch $DIR/$DIR2/file2 $DIR/$DIR2/file2a $DIR/$DIR2/file2b
cvs add $DIR/$DIR2/file2 $DIR/$DIR2/file2a $DIR/$DIR2/file2b
sleep 2
mkdir $DIR/$DIR2/$DIR20
mkdir $DIR/$DIR2/$DIR21
cvs add $DIR/$DIR2/$DIR20 $DIR/$DIR2/$DIR21
sleep 2
touch $DIR/$DIR2/$DIR20/file20 $DIR/$DIR2/$DIR21/file21
cvs add $DIR/$DIR2/$DIR20/file20 $DIR/$DIR2/$DIR21/file21
sleep 2
touch $DIR/$DIR2/$DIR20/file20a $DIR/$DIR2/$DIR21/file21a
cvs add $DIR/$DIR2/$DIR20/file20a $DIR/$DIR2/$DIR21/file21a
sleep 2
touch $DIR/$DIR2/$DIR20/file20b $DIR/$DIR2/$DIR21/file21b
cvs add $DIR/$DIR2/$DIR20/file20b $DIR/$DIR2/$DIR21/file21b
sleep 2
touch $DIR/$DIR2/$DIR20/file20c $DIR/$DIR2/$DIR21/file21c
cvs add $DIR/$DIR2/$DIR20/file20c $DIR/$DIR2/$DIR21/file21c
sleep 2
touch $DIR/$DIR2/$DIR20/file20d $DIR/$DIR2/$DIR21/file21d
cvs add $DIR/$DIR2/$DIR20/file20d $DIR/$DIR2/$DIR21/file21d
sleep 2

cvs add $DIR/file*
sleep 2
cvs ci -m "" $DIR