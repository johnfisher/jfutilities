#!/usr/bin/perl -w
# 
################### ZNYX NETWORKS ####################			
##### sftp.backup.pl				 #####
##### Check out using the zbin project.		 #####
#
# Purpose:
# copy tgz tarballs from liberace and tiger and pt and monk
# copy some files up to Fremont
# designed to be run nightly

# call sftp.backup.pl <username> <password> [test | ]  

# Notes:
# Uses naming pattern ($filespec) and target location $bkfile_path to look for files stored on
# @servers . the files are ftp'd over to a location on the local machine $storefile_path
# use in conjunction with cron-driven shellscripts that create the tarballs on the target machines
#
################## TRACE #########################################################
# trace writes to a file; each time the web page is run it creates a new file
# switch the > symbol to >> to accumulate traces instead
# to stop trace globally edit the $traceflag  flag in Ztts.pm
#

#######################################################

use strict;
use diagnostics;
use Net::FTP ;
use Mail::Sendmail ;
use Net::SSH ;
use Net::SFTP::Recursive;
use Shell qw(ls) ;
no warnings;	


##################################################################################

my @servers = ( "pt" ) ;
my $bkfile_path = '/home/jfisher/test' ;
my $local_bkpath = '/zbackups_local';
my $storefile_path = '/zbackups';
my $cvsrepos_path  = '/usr/local/cvs' ;
my $filespec = ".zbackup.tgz" ;
my $remote_filespec = "*remote.zbackup.tgz" ; # use command line bash syntax
my $remote_filespec_regex = '.*remote\.zbackup\.tgz' ;
my $target = "pt" ; # place to put stuff from this server
my $remote = "208.2.156.27" ; #server in Fremont
my $errflag = 1; # if set to 1 than send email to admin
my $admin = 'john.fisher@znyx.com';

my $user = $ARGV[0] or Expire("ARGS:  couldn't get user ");
my $password = $ARGV[1] or Expire("ARGS:  couldn't get password ");
my $start = $ARGV[2] || '';  # now optional # hours on a 24 hour clock e.g. "17" equals start between 5:00 pm and 5:30
my $arg = $ARGV[3] ; # optional for testing


### trace and error message handling
my $tracefile = "> /tmp/ftp.backup.log" ;
# Sub to wrap generic trace (see ztts.pm) ; 
# used simply to make code easier to cut&paste and read
sub TT { 
	my $text = "\n" . shift @_ ;
	open FILEHANDLE , $tracefile or die "TracetoFile: can't open path! ";
				print FILEHANDLE  $text or die "TracetoFile: couldn't print to file, path !";
				close FILEHANDLE ;
			
}
my $errmsg;
sub ERR { 
	my $msg =  shift @_ ;
	if ( $errflag == 0 ) { $errflag = 1; }
	$errmsg .= $msg ;
	TT("\n ERROR: \n $msg");
			
}
use Sys::Hostname;
my $host = hostname(); # acceptable hosts pt
unless ( $host eq "pt" ) { print "/n ERROR: /n sftp.backup.pl--> bad hostname = $host\n "  ; die; }

# now start a fresh file
TT( "Starting  sftp.backup.pl - waiting for startime of $start:00 24 hr clock \n ");
# now switch to append mode
$tracefile = ">> /tmp/ftp.backup.log" ;
# sample usage:   TT(  "$0:<SUBname>  ");
# use to write trace statements to a file, one file per .pl or .cgi file
# set variable $traceflag at the beginning of this file to "on" to enable trace across all files 
# you may need to adjust permissions in the  directory

if (  $arg eq "test" ) {
	print " \n running tests.....\n";
	# timestamp and restart log
	$tracefile = "> /tmp/ftp.backup.log" ;
	my $startdate = GetTime("stamp") ;
	TT( "New run of  sftp.backup.pl $startdate TEST mode\n ");
	$tracefile = ">> /tmp/ftp.backup.log" ;
	SFTPExport();
	if ( $errflag == 1 ) { 
		print "\nerror message: $errmsg \n";  #send an email with errors to admin
	}else{
		print "\ntest backup complete\n" ;
	}
	print " \n done with tests.....\n";
	exit;
}elsif ( $arg eq "recurse" ) {
	print " \n running recursive ssh tests.....\n";
	# timestamp and restart log
	$tracefile = "> /tmp/ftp.backup.log" ;
	my $startdate = GetTime("stamp") ;
	TT( "New run of  sftp.backup.pl $startdate RECURSIVESSHTEST mode\n ");
	$tracefile = ">> /tmp/ftp.backup.log" ;
	SFTP_Recurse_Export();
	if ( $errflag == 1 ) { 
		print "\nerror message: $errmsg \n" ;  #send an email with errors to admin
	}else{
		print  "\nrecursion test backup complete\n" ;
	}
	print " \n done with recurse tests.....\n";
	exit;


}else {
	Main();
}

#############################################
# get files from servers listed matching filespec and move to local backup dir
# for export to local backup or remote backup server


sub Main {

SFTPExport();



}





#############################################
sub Expire {
	my $text = $_[0] ;
	TT( "\n $text" ) ;
	TT( " \n dying.....\n");
	die( $@ ) ;
} # end sub Expire



###############################################
sub CleanList {
	my $list = $_[0] ;
	my $dest = $_[1] ; # local or remote or all
	TT("Cleanlist starting...  $list , $dest ");
	my @files;
	foreach my $line ( @$list ) {
		if ( $dest eq "local" ){
		
			 if ( $line =~ /$filespec$/ ) { 
				 push ( @files , $line );  
				TT("CleanList local: file is $line ");
			 }else { 
				TT("CleanList local: ignoring $line ");
			 }
			 
		}elsif ($dest eq "remote" ) {
			if ( $line =~ /$remote_filespec_regex$/ ) { 
				push ( @files , $line );  
					TT("CleanList remote: file is $line ");
			}else { 
					TT("CleanList remote: ignoring $line ");
			}
			
		}elsif ($dest eq "all" ) {
				TT("Cleanlist: dest = $dest line = $line");
			if ( $line =~ /$remote_filespec_regex$/ || $line =~ /$filespec$/ ) { 
				push ( @files , $line );  
					TT("CleanList all: file is $line ");
			}else { 
					TT("CleanList all: ignoring $line ");
			}
			
		}else {ERR("Cleanlist: got no proper destination arg");}
	 }
	 return \@files ;
 } # end sub CleanList
 
 
###############################################
# exports this servers files in $local_bkpath that matches $filespec and $remote_filsespec to $target/$storefile_path
sub ExportBK {
	
	# get an arrayref to a cleaned list of files that match $filespec
	chdir $local_bkpath ;
	my $dirtylist =    ls() or Expire("Export:  couldn't ls to get files from  $bkfile_path ");
	my @filearray = split /\s/ , $dirtylist ;
	my $list = CleanList( \@filearray, "all" ) or Expire("Export:  couldn't CleanList  ") ;
	my $ftp;
	eval {
		# ftp to target and send files
		$ftp = Net::FTP->new( $target ) or ERR(" Export: couldn't ftp to $target ");
		$ftp->login( $user , $password ) or ERR("Export:  couldn't login to $target ");
		$ftp->cwd( $storefile_path ) or ERR("Export:  couldn't cd to  $storefile_path on $target ");
	};
	if ($@ ) { ERR("ExportBK had fatal error ftp'ing to $target");}

	foreach my $file ( @$list ) {
		eval {
		# ftp::get each file
		
				TT("Export: Putting $file ");
			$ftp->put( $file ) ;
		
		};
		if ($@ ) { ERR("ExportBK had fatal error ftp getting to $target");}
	}
	

} # end sub Export
 
 ###############################################
 # securely exports everything in $bkfile_path that matches $remote_filespec to $remote/$storefile_path
 # see http://search.cpan.org/dist/Net-SSH-Perl/lib/Net/SSH/Perl.pm
 #$shell->{sftp}->ls($arg[0] || $shell->{pwd},
 #       sub { print $_[0]->{longname}, "\n" });

 sub SFTPExport {
 	
 	# get an arrayref to a cleaned list of files that match $filespec
 	chdir $bkfile_path ;
 	my $dirtylist =    ls() or Expire("ExportSFTP:  couldn't ls to get files from  $bkfile_path ");
 	my @filearray = split /\s/ , $dirtylist ;
 	my $list = CleanList( \@filearray, "remote" ) or Expire("ExportSFTP remote:  couldn't CleanList  ") ;
 	my %args = (user => $user,
 			password => $password ,
 			debug => 0) ; # set to one for verbose
 	
 	foreach my $file ( @$list ) {
		eval {
			my $sftp = Net::SFTP->new($remote, %args) ;
			my $storefile = $bkfile_path. '/' . $file ;
				TT("SFTPExport: Putting $file  on $remote");
			
			$sftp->put($storefile, $file) ;# can't use "or die" here without filtering the return
				TT("SFTPExport: after putting  $file onto $remote at ");
		
		};
		if ($@ ) { ERR("SFTPExport had fatal error sftp'ing to $remote" . $@);}
	}
	

 	
 } # end SFTPExport
 
 # use a recursive class instead of shipping tarballs
 # problems arose with large 2gig tarballs timing out
 # switch to public key encryption
 sub SFTP_Recurse_Export {
 	
 	
 	chdir  $cvsrepos_path;
 	
 	my %args = (user => $user, password =>$password  , debug => 0) ; # set to one for verbose
 	
 	
	my $sftp = Net::SFTP::Recursive->new($remote, %args) ;
	my $remote_path = 'zbackups/cvsrepos/rdr' ;

	$sftp->rput( $cvsrepos_path . '/rdr' , $remote_path) ;# can't use "or die" here without filtering the return
				
		
		if ($@ ) { ERR("SFTPExport had fatal error sftp'ing to $remote" . $@);}
	
	

 	
 } # end SFTPExport
 
 # see Mail::Sendmail http://search.cpan.org/author/MIVKOVIC/Mail-Sendmail-0.79/Sendmail.pm
 
 sub Send {
 		TT( "Messages::Send starting...");
 
 	my $mailto = $admin;
 	my $subject;
 	if ( $errflag == 1 ) { $subject = "ERROR message on BACKUP" ;} else { $subject = " Message from Zbackup" ; }
 	my $message = $_[0] or TT( " Send didn't get message argument") ;
 	my $mailfrom = 'zbackup@pt.znyx.com' ;
 
 	my %mail = ( To      =>  $mailto ,
 	             From    => $mailfrom,
 	             Subject => $subject ,
 	             Message => $message
 	            );
 	            
 	### logging
 	my $rawmail = "Email sent to: " . $mailto . " \nSubject: " . $subject . " \nMessage: " . $message ;
 	TT( "Messages::Send tried to send message: $rawmail " ) ;

 	sendmail(%mail) or TT(" Messages::Sendmail::error $rawmail $!");	
 	
} # end Send

#///////////// GetTime ////////////////////#
sub GetTime {
 	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time); 
 	my $arg = $_[0] or  CGIError(" Ztts::GetTime got no mode argument $_[0]");
 	$year =~ s/^1/20/ ; # adjust weird year ( 2003 comes as "103" )
	$mon++; # zero-based months - jeez!
 	my $result;

 	 if ( $arg eq "time" ){ $result = $hour . ":" . $min . ":" . $sec ; }
 	 elsif ( $arg eq "day" ) { $result = $wday; } 	 
 	 elsif ( $arg eq "shortstamp" ) { $result = $hour . "-" . $min . "-" . $sec ; } 	 
 	 elsif ( $arg eq "stamp" ) { $result = $mon ."/". $mday. "/" . $year ." ". $hour .":". $min .":". $sec ; }
 	 elsif ( $arg eq "date" ){ $result = $mon . "/" . $mday . "/" . $year ;}
 	 elsif ( $arg eq "hour" ){ $result = $hour ;} 	 
 	 else { Expire ( "GetTime got invalid argument $arg");}
 	 
 	 ### to get basic UNIX like timestamp just say $now_string = localtime;  # e.g., "Thu Oct 13 04:54:34 1994
 	 
 	 return $result;
 	 
  }
  
1;
