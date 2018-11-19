#!/usr/bin/perl -w
#
# pt_bkup.pl
# by John Fisher john.fisher@znyx.com
#
# ASSUMPTIONS:
# Have:  perl 5+; 

# PURPOSE:
# tarball various user directories on pt
# and copy the tarballs to zbackups* dir for ftp pickup by the script running on  backup machine



use diagnostics;
use strict;
use English ;
require Carp;
use Mail::Sendmail ;


my $log =  "/tmp/pt_bkup.pl.log" ;
my $dest = "/zbackups_outgoing" ;
my $date = localtime(); 
my $debug = 1 ;
my $admin = 'john.fisher@znyx.com';

#my $pt_web = $dest . "/pt_web.pt.remote.zbackup.tgz" ;
#my $pt_web_src = "/var/www" ;
my $pt_adminfiles = $dest . "/pt_admin.pt.remote.zbackup.tgz";
my $pt_adminfiles_src = "/etc" ;
my $pt_mysql = $dest . "/pt_mysql.pt.remote.zbackup.tgz";
my $pt_mysql_src = "/var/lib/mysql" ;
my $packages_text  = system ("dpkg -l > /tmp/dpkgoutput") ;
my $packages_src = "/tmp/dpkgoutput" ;
my $packages = $dest . "/pt_packages.pt.remote.zbackup.tgz";
my $errflag = 0;
my $errmsg;
sub ERR { 
	my $msg =  shift @_ ;
	 $errflag = $errflag + 1; 
	$errmsg .= $msg ;
	WriteLog("\n ERROR: \n $msg");
			
}

#///////////// pre-run Section ////////////////////#
ResetLog();

eval {
	system("tar czf /zbackups_outgoing/cvs_repos1.remote.zbackup.tgz --exclude='released' /usr/local/cvs/r* "); 
	system("md5sum /zbackups_outgoing/cvs_repos1.remote.zbackup.tgz > /zbackups_outgoing/cvs_repos1.md5sum.pt.remote.zbackup.txt");
	system("tar czf /zbackups_outgoing/cvs_repos2.remote.zbackup.tgz --exclude='r*' /usr/local/cvs/* ");
	system("md5sum /zbackups_outgoing/cvs_repos2.remote.zbackup.tgz > /zbackups_outgoing/cvs_repos2.md5sum.pt.remote.zbackup.txt");
	system("tar chzf $pt_adminfiles /etc");
	system("tar czf /zbackups_outgoing/git_repos.remote.zbackup.tgz  /var/git/* ");
	system("tar czf /zbackups_outgoing/svn_repos.remote.zbackup.tgz  /var/svn/* ");
	};
	if ($@ ) { 
		ERR(" Failed to tarball or checksum CVS repositories! See pt $log" . $@);	
	}else {
		WriteLog( "\n Tarballed cvs_repos1 md5sum cvs_repos2 md5sum and admin files");
	}



#///////////// Main Section ////////////////////#


#Tarball ( $pt_web , $pt_web_src ) ;
#WriteLog ( " \n Backed up $pt_web_src $date " ) ;
#Tarball ( $pt_adminfiles , $pt_adminfiles_src ) ;
#WriteLog ( " \n Backed up $pt_adminfiles $date " ) ;
Tarball ( $packages , $packages_src ) ;
WriteLog ( " \n Backed up $packages_src $date " ) ;


#///////////// Set Permissions on tarballs ////////////////////#
opendir DIRHANDLE, $dest ;
my @files = readdir DIRHANDLE ;
closedir DIRHANDLE ;

chown ("501" , "501" , "*.tgz" ) ; # 501 is the uid for zbackup on hawk 

WriteLog(" \n Changed files at $dest to new owner uid. \n ######### END OF BACKUP at $date #########");

if ( $errflag > 0 ) { 
	Send(  $errmsg );  #send an email with errors to admin
}

############### SUBS ############################################################

#///////////// WriteLog ////////////////////#
sub WriteLog {
	my $text = $_[0] ;
	$date = localtime(); 
	$text = $date . " " . $text ;
		if ( $debug ) { print " \n running WriteLog at $date for $text" ; }

	open ( OUTFILEHANDLE , ">> $log" ) ; # open for appending with >>
	print OUTFILEHANDLE "$text\n " ;			
	close OUTFILEHANDLE;

	
} # end sub WriteLog


#///////////// ResetLog ////////////////////#
sub ResetLog {
	my $text = "Starting log file at $date..... \n" ;
		if ( $debug ) { print " \n running ResetLog for $text" ; }

	open ( OUTFILEHANDLE , "> $log" ) ; # open for writing with >
	print OUTFILEHANDLE "$text" ;			
	close OUTFILEHANDLE;

	
} # end sub ResetLog

#///////////// Tarball ////////////////////#
# call Tarball( dest , src ) 
#### DOES NOT DUMP SYMLINKS - SEE -h  - ADDED TO P[RTECT WHEN TARBALLING /ETC
sub Tarball {
	my $dest = $_[0] ;
	my $src = $_[1] ;
	my $cmd = "tar hczf " . " " . $dest . " " . $src ;
		if ( $debug ) { print " \n running Tarball for $cmd" ; }
	
	system( $cmd ) == 0 or WriteLog "\n********* error ***********\nCouldn't run: $cmd \n****************************";
	

	
} # end sub Tarball

# see Mail::Sendmail http://search.cpan.org/author/MIVKOVIC/Mail-Sendmail-0.79/Sendmail.pm
 
 sub Send {
 		Writelog( "Messages::Send starting...");
 
 	my $mailto = $admin;
 	my $subject;
 	if ( $errflag > 0 ) { $subject = "$errflag ERRORS on PT BACKUP" ;} else { $subject = " Message from PT Zbackup" ; }
 	my $message = $_[0] or Writelog( " Send didn't get message argument") ;
 	my $mailfrom = 'zbackup@pt.znyx.com' ;
 
 	my %mail = ( To      =>  $mailto ,
 	             From    => $mailfrom,
 	             Subject => $subject ,
 	             Message => $message
 	            );
 	            
 	### logging
 	my $rawmail = "Email sent to: " . $mailto . " \nSubject: " . $subject . " \nMessage: " . $message ;
 	Writelog( "Messages::Send tried to send message: $rawmail " ) ;

 	sendmail(%mail) or Writelog(" Messages::Sendmail::error $rawmail $!");	
 	
} # end Send



1;
