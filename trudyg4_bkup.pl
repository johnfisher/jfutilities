#!/usr/bin/perl -w
#
# trudyg4_bkup.pl
# by John Fisher john.fisher@znyx.com
#
# ASSUMPTIONS:
# Have:  perl 5+; 

# PURPOSE:
# tarball various user directories on liberace
# and copy the tarballs to /tmp for ftp pickup by the script running on PT ( or future backup machine)



use diagnostics;
use strict;
use English ;
require Carp;

my $date = localtime;
my $log =  "/var/log/backup.log" ;
my $dest = "/zbackups_outgoing" ;

my $debug = 1 ;

my $build1 = $dest . "/build1.trudyg4.zbackup.tgz" ;
my $build1_src = "/home/build/buildenv/potato/builds/work1" ;
my $build2 = $dest . "/build2.trudyg4.zbackup.tgz" ;
my $build2_src = "/home/build/buildenv/potato/builds/work2" ;
my $build3 = $dest . "/build3.trudyg4.zbackup.tgz" ;
my $build3_src = "/home/build/buildenv/potato/builds/work3" ;


#///////////// Main Section ////////////////////#
ResetLog();

Tarball ( $build1 , $build1_src ) ;
WriteLog ( " \n Backed up $build1_src $date " ) ;

Tarball ( $build2 , $build2_src ) ;
WriteLog ( " \n Backed up $build2_src $date " ) ;

Tarball ( $build3 , $build3_src ) ;
WriteLog ( " \n Backed up $build3_src $date " ) ;



#///////////// Set Permissions on tarballs ////////////////////#
opendir DIRHANDLE, $dest ;
my @files = readdir DIRHANDLE ;
closedir DIRHANDLE ;

chown ("1009" , "1009" , "*.tgz" ) ; # 1010 is the uid for zbackup on liberace

#///////////// WriteLog ////////////////////#
sub WriteLog {
	my $text = $_[0] ;
		if ( $debug ) { print " \n running WriteLog for $text" ; }

	open ( OUTFILEHANDLE , ">> $log" ) ; # open for appending with >>
	print OUTFILEHANDLE "$text\n " ;			
	close OUTFILEHANDLE;

	
} # end sub WriteLog


#///////////// ResetLog ////////////////////#
sub ResetLog {
	my $text = "Starting log file ..... \n" ;
		if ( $debug ) { print " \n running ResetLog for $text" ; }

	open ( OUTFILEHANDLE , "> $log" ) ; # open for writing with >
	print OUTFILEHANDLE "$text" ;			
	close OUTFILEHANDLE;

	
} # end sub ResetLog

#///////////// Tarball ////////////////////#
# call Tarball( dest , src ) 
sub Tarball {
	my $dest = $_[0] ;
	my $src = $_[1] ;
	my $cmd = "tar czf " . " " . $dest . " " . $src ;
		if ( $debug ) { print " \n running Tarball for $cmd" ; }
	
	system( $cmd ) == 0 or WriteLog "\n********* error ***********\nCouldn't run: $cmd \n****************************";
	

	
} # end sub Tarball



1;
