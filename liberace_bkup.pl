#!/usr/bin/perl -w
#
# liberace_bkup.pl
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

my $swall1 = $dest . "/swall.liberace.remote.zbackup.tgz" ;
my $swall1_src = "/home/swall/buildenv/potato/usr/src/work2" ;


my $kathy = $dest . "/kathy.liberace.remote.zbackup.tgz" ;
my $kathy_src = "/home/kathy/buildenv/potato/work/*" ;
my $bobm = $dest . "/bobm.liberace.remote.zbackup.tgz" ;
my $bobm_src = "/home/bobm/buildenv/potato/usr/src" ;
my $bguilfoyle = $dest . "/bguilfoyle.liberace.remote.zbackup.tgz" ;
my $bguilfoyle_src = "/home/bguilfoyle/buildenv/potato/work/*" ;



my $deb = $dest . "/deb.liberace.remote.zbackup.tgz" ;
my $deb_src = "/home/deb/buildenv/potato/usr/src/*" ;


#///////////// Main Section ////////////////////#
ResetLog();

Tarball ( $swall1 , $swall1_src ) ;
WriteLog ( " \n Backed up $swall1_src $date " ) ;


Tarball ( $kathy , $kathy_src ) ;
WriteLog ( " \n Backed up $kathy_src  $date" ) ;

Tarball ( $bobm , $bobm_src ) ;
WriteLog ( " \n Backed up $bobm_src  $date" ) ;

Tarball ( $bguilfoyle , $bguilfoyle_src ) ;
WriteLog ( " \n Backed up $bguilfoyle_src  $date" ) ;

Tarball ( $deb , $deb_src ) ;
WriteLog ( " \n Backed up $deb_src  $date" ) ;


#///////////// Set Permissions on tarballs ////////////////////#
opendir DIRHANDLE, $dest ;
my @files = readdir DIRHANDLE ;
closedir DIRHANDLE ;

chown ("1010" , "1010" , "*.tgz" ) ; # 1010 is the uid for zbackup on liberace

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
