#!/usr/bin/perl -w
#
# tiger_bkup.pl
# by John Fisher john.fisher@znyx.com
#
# ASSUMPTIONS:
# Have:  perl 5+; 

# PURPOSE:
# tarball various user driectories on tiger
# and copy the tarballs to /tmp for ftp pickup by the script running on PT ( or future backup machine)



use diagnostics;
use strict;
use English ;
require Carp;
# use Mail::Sendmail ; # tiger isn't set up for this, and perl is out of date with no cpan

my $date = localtime;
my $log =  "/var/log/backup.log" ;
my $dest = "/zbackups_outgoing" ;
my $errflag = 0 ;

my $debug = 1 ;



my $bobm= $dest . "/bobm.bobcat.remote.zbackup.tgz" ;
my $bobm_src = "/home/bobm/buildenv/potato/usr/src/rdr" ;




#///////////// Main Section ////////////////////#
ResetLog();




Tarball ( $bobm  , $bobm_src ) ;
WriteLog ( " \n Backed up $bobm_src  $date" ) ;


#///////////// Set Permissions on tarballs ////////////////////#
opendir DIRHANDLE, $dest ;
my @files = readdir DIRHANDLE ;
closedir DIRHANDLE ;

chown ("1010" , "1010" , @files ) ; # 1010 is the uid for zbackup on tiger

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
	eval {
		my $cmd = "tar czf " . " " . $dest . " " . $src ;
		if ( $debug ) { print " \n running Tarball for $cmd" ; }
		system( $cmd ) == 0 or WriteLog( "Couldn't run: $cmd ") ;
	}
	#if ($@ ) { 	ERR("tiger had fatal error making tarball"); 	}

	
} # end sub Tarball

sub ERR { 
	my $msg =  shift @_ ;
	if ( $errflag == 0 ) { $errflag = 1; }
	#$errmsg .= $msg ;
	WriteLog("\n ERROR: \n $msg \n ");
	exit;
			
}



1;
