#!/usr/bin/perl -w
#
# diz_bkup.pl
# by John Fisher john.fisher@znyx.com
#
# ASSUMPTIONS:
# Have:  perl 5+;  

# PURPOSE:
# tarball various user directories on diz
# and copy the tarballs to /tmp for ftp pickup by the script running on backup machine



use diagnostics;
use strict;
use English ;
require Carp;

my $date = localtime;
my $log =  "/var/log/backup.log" ;
my $dest = "/zbackups_outgoing" ;

my $debug = 1 ;

my $diz_web = $dest . "/diz_web.diz.remote.zbackup.tgz" ;
my $diz_web_src = "/var/www/*" ;

		

#///////////// Main Section ////////////////////#
ResetLog();

Tarball ( $diz_web , $diz_web_src ) ;
WriteLog ( " \n Backed up $diz_web_src $date " ) ;


#///////////// Set Permissions on tarballs ////////////////////#
opendir DIRHANDLE, $dest ;
my @files = readdir DIRHANDLE ;
closedir DIRHANDLE ;

chown ("1002" , "1002" , "*.tgz" ) ; # 1010 is the uid for zbackup on diz

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
