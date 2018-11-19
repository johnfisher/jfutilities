#!/usr/bin/perl -w
#
# cvsrelnotes.pl
# by John Fisher john.fisher@znyx.com
#
# ASSUMPTIONS:
# Have: cvs, perl 5+; 
# This script is NOT tested on NT or Solaris.
# You must be in topmost directory of cvs tree.
# The directory must be writable.
# You must be logged in to cvs.


use diagnostics;
use strict;
use English ;
require Carp;
no warnings;

#///////////// set variables ////////////////////#

my $debug = 0;	# set to 1 when debugging


# print   "\n\n Notes starting .........\n";
			#if ( $debug > 5 ) { # print   " \n\n<><><><><><><><><><><><>\n debugcount is :$debugcount linecount is  $finallinecount \n\n";}
QandDirty();


my @files;
sub QandDirty {
	my @results;
	# print   " \nq&D starting..\n";
	open (LOGFILEHANDLE, "notes.good") ;
	while (<LOGFILEHANDLE>){
			push  @files , $_;
	}
	close LOGFILEHANDLE;
	my $linecount = scalar @files;
	print   "\n\n sizeof files array = $linecount\n";
	my $i;
	for ( $i =0 ; $i < $linecount ; $i++) {
		my $line = $files[$i];
		#print   "\nfor loop  line is $line\n iteration is $i \n";
		if ( $line =~ /CVS File / ) {
			print "===================================\n\n\n" ;
			# print"\n got a file, now getting logs....\n";
			#push  @results, $line;
			print "$line\n----------------------------\n";
			#print " pushing ============================ \n $line";
			my ($lrev,$orev);
			while ( $files[$i] !~ /keyword substitution:/ ){
				$i++;
				# print   "\n this line is $l";
				if ( $files[$i] =~ /RDR3_1_1\+RDRABSTRACTbranch:\s(.+)$/ ) {
					$lrev = $1;
					#print   "\n lrev is $lrev\n";
				}
				if (  $files[$i] =~ /RDR3_1_0d\+RDRABSTRACTbranch:\s(.+)$/ ){ 
					
					$orev = $1; 
					#print   "\n orev is $orev\n";
				}
			}#while
			while ( $files[$i] !~ /revision\s$lrev/ ){	
				#print"\n looking for revision $lrev - number $i\n";
				$i++;
			}
			if ( $files[$i] =~ /revision\s$lrev/ ) {
					
				 #print   " \n pushing revision $lrev  ";
				#push  @results, $files[$i] ;
				print "$files[$i]";
				$i++;
			}
			while ( $files[$i] !~ /revision\s$orev/ && $files[$i] !~ /==============/) {
				#print "\n number $i pushing onto results: $ll";
				#push  @results, $files[$i] ;
				print "$files[$i]";
				if ( $i > $linecount) { die;}
				$i++;
			}
	
		}#if
		#my $size = scalar @results;
		# print   " \n sizeof results is $size";
	}#for
			 #print   " \n\n\n\n\n\n\n\n XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXx\n\n\n";

	#foreach my $s ( @results ){  print   "\n $s";}
	
	
} # end Q&D

print "\n\n.....The End.....";

1;






