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


my $kathy = $dest . "/kathy.tiger.remote.zbackup.tgz" ;
my $kathy_src = "/home/kathy/potato/src" ;

my $bobm = $dest . "/bobm.tiger.remote.zbackup.tgz" ;
my $bobm_src = "/home/bobm/buildenv/potato/usr/src" ;

my $swall = $dest . "/swall_tip.tiger.remote.zbackup.tgz" ;
my $swall_src = "/home/swall/buildenv/potato/usr/src/tip" ;

my $bguilfoyle = $dest . "/bguilfoyle.tiger.remote.zbackup.tgz" ;
my $bguilfoyle_src = "/home/bguilfoyle/buildenv/potato/usr/src" ;

my $cpage= $dest . "/cpage.tiger.remote.zbackup.tgz" ;
my $cpage_src = "/home/cpage/buildenv/potato/usr/src" ;



#///////////// Main Section ////////////////////#
ResetLog();


Tarball ( $kathy , $kathy_src ) ;
WriteLog ( " \n Backed up $kathy_src  $date" ) ;

Tarball ( $bobm  , $bobm_src ) ;
WriteLog ( " \n Backed up $bobm_src  $date" ) ;

Tarball ( $swall  , $swall_src ) ;
WriteLog ( " \n Backed up $swall_src  $date" ) ;

Tarball ( $bguilfoyle  , $bguilfoyle_src ) ;
WriteLog ( " \n Backed up $bguilfoyle_src  $date" ) ;


Tarball ( $cpage  , $cpage_src ) ;
WriteLog ( " \n Backed up $cpage_src  $date" );


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

#  # see Mail::Sendmail http://search.cpan.org/author/MIVKOVIC/Mail-Sendmail-0.79/Sendmail.pm
#  
#  sub Send {
#  		WriteLog( "Messages::Send starting...");
#  
#  	my $mailto = 'john.fisher@znyx.com';
#  	my $subject = "ERROR on TIGER nightly BACKUP";
#  	
#  	my $message = $_[0]  ;
#  	my $mailfrom = 'zbackup@tiger.znyx.com' ;
#  
#  	my %mail = ( To      =>  $mailto ,
#  	             From    => $mailfrom,
#  	             Subject => $subject ,
#  	             Message => $message
#  	            );
# 
#  	sendmail(%mail) ;
#  	 WriteLog( "MAIL sent: $mailto \n $subject \n $message \n");
# 	
#  	
# } # end Send

1;
