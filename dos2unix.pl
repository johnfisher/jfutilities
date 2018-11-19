#!/usr/bin/perl -w
#
# dos2unix.pl
# by John Fisher john.fisher@znyx.com
#
# ASSUMPTIONS:
# Have: perl 5+; 
# This script is NOT tested on NT or Solaris.
# gets rid of control-M .


use diagnostics;
use strict;
require Carp;
no warnings;
use File::Find;
#///////////// set variables ////////////////////#
my $debug = 0;	# set to 1 when debugging

my @errors ; # holds non-fatal error messages


#////////////// usage ///////////////////////////#
my $usage = qq|\n===================== USAGE =====================================\n
NAME: \t\tdos2unix.pl  
PURPOSE: \tRemove controlMs in text file  
\n
USAGE: \t\tdos2unix.pl  <filespec> [<mode>] [1-10]
defaults to recursive listing and checking ( mode c )
NO WILDCARDS use "." for all files


REQUIRES: \tPerl5+ , perl CWD. \n

DEBUGGING: \tadd 1-10 as the 3rd argument to invoke trace.
		
=================================================================\n|;
	
#///////////// get parameters ////////////////////#
my $filespec = $ARGV[0] ||  ".";
my $mode ;
$mode = $ARGV[1] or $mode = "c" ; # c = just check r = make changes
$debug = $ARGV[2] ;
	
	if ( $debug > 0) { print "\nStarting dos2unix \n filespec = $filespec mode = $mode debug = $debug\n " ; }

if ($filespec =~/help|\?/  ) { 
	print " \n\n$usage\n";
	exit;
}
unless ( $mode eq "c" || $mode eq "r" ) {
	print " \n\n$usage\n";
	exit;
}
#///////////// run here ////////////////////#


if ( $filespec eq "*" ){ # if there is only a star
		if ( $debug > 1 ) { print "\n  filespec has star >>$filespec<<";}

	$filespec =~ s/\*/./ ; # convert wildcard to dot
		if ( $debug > 1 ) { print "\n  star filespec now >>$filespec<<";}

}elsif ( $filespec =~ /\*/m ||  $filespec =~ /.*\*/m ||  $filespec =~ /\*.*/m ){
	print " \n\n$usage\n";
	exit;
}


find(\&DoIt, $filespec);
#find( \&Test, "./" ) ;

sub Test {
	my $file = $File::Find::name;
	print "\nTest: $file ";
}

sub DoIt {
  	my $fullpath = $File::Find::name ;
  	my $file = $_ ;
  				if ( $debug > 4 ) { print "\n $fullpath  : starting DoIt\n.................\n";}
	if ( $file =~ /CVS/  ) {
			if ( $debug > 5 ) { print "\n $file : CVS don't do anything";}
			return;
	}

	  open (FILE, "< $file") or die "Couldn't open $fullpath - $!";

	  my @lines = <FILE>;
	  close FILE;
			if ( $debug > 2 ) { print "\n $file : got contents";}
	  my $flag = "no";
	  my @clean;
	  foreach my $line ( @lines ) {
				if ( $debug > 4 ) { print "\n $file : line : $line";}

		if ($line =~ s/\r/\n/m){
				if ( $debug > 2 ) { print "\n $file : line : $line set flag to yes";}

			$flag = "yes" ;
		}
		push @clean, $line ;

	  }

		if ( $flag eq "yes" ) { 

			if ($mode eq "r" ) {  # make changes
				open FILE, ">$file" or die "Couldn't open $fullpath to write....\n";
				print FILE @clean or die "\n\nCouldn't print to  $fullpath ....\n";
				close FILE;
				print "\nCleaned $fullpath \n" ; 
				
			}elsif ($mode eq "c" ) {
				print "\nWin32 line endings: $fullpath \n" ; 
				
			}else{
				print "\n$fullpath: bad mode \n" ; 
			}
		}else{
			if ( $debug > 2 ) {print "\n$file flag = $flag\n" ; }
		}

}# end DoIt

if ($mode eq "r" ) {  # make changes
		print "\n\n ..... finished cleaning ....\n";

}elsif ($mode eq "c" ) {
	print "\n\n ..... finished checking ....\n";
}



1;