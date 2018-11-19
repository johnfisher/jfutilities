#!/usr/bin/perl -w
#
# autobuild.pl
# by John Fisher john.fisher@znyx.com
#
# ASSUMPTIONS:
# Have: cvs, perl 5+; 
# This script is NOT tested on NT or Solaris.
# You must be logged in to cvs.
##
##### IMPORTANT CHROOT INFO #########
# the target server runs chroot so we can have controllable build environments.
# because of the quirks of cron and ssh - we have to log in as root and run chroot for each
# command sent through NetSSH


use diagnostics;
use strict;
use Cwd;
use Net::FTP ;
use Mail::Sendmail ;
#use Shell;
#use Shell::Source ;
require Carp;
#no warnings;
 
#///////////// set variables ////////////////////#

my $target = "pt" ; # place to built images for testing
my $today = 7 ; #GetTime("day");
my $storefile_path = "/ut/$today"  ;
my $buildpath = "/builds/autobuild/$today" ;
my $admin = 'admin@pt.znyx.com';
my $audience = 'sbo@znyx.com'; #'bob.guilfoyle@znyx.com,scott.shannon@znyx.com,kevin.robinson@znyx.com' . ',' . $admin ;
my $mailfrom = 'AUTOBUILD@pt.znyx.com' ;
my $message;
my $user = "build" ;
my $autolog ="/tmp/autobuild.log" ;
my $err = "ERROR: " ;

 
#////////////// usage ///////////////////////////#
my $usage = qq|\n===================== USAGE =====================================\n
NAME: \t\tautobuild.pl  
PURPOSE: \tBuild OA nightly as a unit test  
\t\tthen ship off initrd for testing 
\t\tthen send success or error message
USAGE: \t\tautobuild.pl <nominal version> <tag> <password> [< debug level 1-10>] > /tmp/autobuild.log
\n 
EXAMPLE:\n
autobuild.pl 3.1.2x RDR3_1xbranch+off-RDR312e  mypassword 1 \n
NOTE:  \t\tthe tag is expected to be one of the build branches, not a release\n
\t\tThe script must be run in an RDR tree, else the tags won't work.

REQUIRES: \tPerl5+ , perl CWD,  CVS \n
To List Tags: \tRun a cvs log Makefile and scroll up.

DEBUGGING: 	add a 1-10 as the 3rd argument to invoke trace.
		
=================================================================\n|;
	
#///////////// get parameter ////////////////////#
my $ver =  $ARGV[0] or  Expire("You must provide a nominal version...\n$usage\n\n");
my $tag = $ARGV[1] or  Expire("You must provide a tag...\n$usage\n\n");
my $password = $ARGV[2] ; 

my $debug_arg = $ARGV[3] ;
my $debug = 0;


#>>>>>>>>>>>>>>>>>>>>>>>> Main <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<#

# make sure its an RDR tag, if not print usage and exit
if ( $tag !~ /^RDR/ ) { Log(" \nMust be an RDR tag....\n $usage "); die; }

# change to the working directory
chdir "$buildpath" or Expire("\nAUTOBUILD: couldn't chdir to $buildpath");

my $date = GetTime("stamp") ;
$message = "AUTOBUILD ADMIN MESSAGE 
started on $date 
for version $ver 
for tag $tag." ;
Send($message, $admin) ;
CleanLog(); 	# empties old log and starts new one, logs initial params too

CheckTag();
	
if ( $debug_arg && $debug_arg eq "test" ) {
	$debug = 10 ;
	Log( "AUTOBUILD DEBUG MODE $debug\nstarting TEST build for >>$tag<<.......  \ndebug level \t>>$debug<< ") ; 
	Test();
	my $log = GetLog() ;
	my $message = "\nAutobuild ADMIN MESSAGE 
	done with test function \n\n$log" ;
	Log ($message) ;
	Send($message, $admin) ;
	
}else {
	if ($debug_arg) {
		if ( $debug_arg !~ /[1-9]/ ){
	 		Expire("\n$usage\n\n");
		}
		$debug = $debug_arg;
	 }
	Log(" Starting normal default build seqeunce...");
	DefaultBuild() ;
	my $t = GetTime("stamp") ;
	my $message = "\nAutobuild ADMIN MESSAGE -- end of default builds at $t \n" ;
	Send($message, $admin) ;
	Log($message);

}



#>>>>>>>>>>>>>>>>>>>>>>>> End Main <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<#

#///////////// Subs Below Here ////////////////////#

#/////////////// DefaultBuild /////////////////#
sub DefaultBuild {
# all non-test formats	

	if ( $debug > 0 ) { Log( "\nDefaultBuild starting...... DEBUG = $debug  ") ; }
	
	my $command =  "/bin/rm -rf 4900 4920 5000 rdr ";
	if ( system( $command ) != 0 ) { Expire("DefaultBuild can't execute $command`");}
	if ( -d "rdr" || -d "4900" || -d "5000") { Expire("DefaultBuild can't delete previous build - $err");}
	Log("DefaultBuild cleaned up build directory...") ;
	# n 5000 build
		my $my5000 = Build("5000") ;
		if ( $my5000 ne "ok" ) {  Send("ADMIN MESSAGE -- 5000 build failed:\n$my5000 $err " , $admin) ; Log("Couldn't send 5000 build failed: $my5000 to $admin $err");}
	
	
	
	### now do 4900 build...
	#my $my4900 = Build("4900");
	#if ( $my4900 ne "ok" ) { Send("ADMIN MESSAGE -- 4900 build failed: \n$my4900 $err " , $admin) ; Log("Couldn't send 4900 build failed: $my4900 to $admin $err");}

	### 4920 build...
	#my $my4920 = Build("4920");
	#if ( $my4920 ne "ok" ) { Send("ADMIN MESSAGE -- 4920 build failed: \n$my4920 $err " , $admin) ; Log("Couldn't send 4920 build failed: $my4920 to $admin $err");}

	
	# if all went well, then announcements were sent....
	
			
} # end sub DefaultBuild

sub Build {
	my $no = $_[0] ;
		
			Log("Build$no starting.....\n");
		chdir "$buildpath" or return "$no error $! can't chdirectory to buildpath: $buildpath  " ;
		my $comd = " /usr/bin/cvs co -r $tag rdr > build.log"  ;
			if ( system ( $comd ) != 0 ){ return "$no Error $! can't run $comd" ;}
			Log("Build$no ran $comd");

		sleep 5 ;
		$comd = "  /bin/mv rdr $no" ;
			if ( system ( $comd ) != 0 ){ return "$no Error $! can't run $comd" ;}
			Log("Build$no ran $comd");

		sleep 5 ;
		chdir "$buildpath/$no/prebuilt/etc" or return "$no Error $! can't chdir to $buildpath/$no/prebuilt/etc";
			Log("Build$no ran chdir $buildpath/$no/prebuilt/etc ");

		SetVersion() or return "$no Error couldn't set version string for $no";

		chdir "$buildpath/$no" or return "$no Error $! can't chdir to $buildpath/$no";
		my $cwd = cwd();
			Log("Build$no ran chdir $buildpath/$no   CWD is $cwd");
		my $com = "/usr/bin/make  unpack  " ;
			if ( system ( $com ) != 0 ){ return "$no Error $! can't run $com" ;}
					Log("Build$no ran $com");
		sleep 10;
		 $com = " /usr/bin/make  build_$no  >> build.log" ;
		if ( system ( $com ) != 0 ){ return "$no Error $! can't run $com" ;}
		
		
		
		
		# trying exec-fork
		# my $child = fork();
# 		Expire( "Build::can't fork $!") unless defined $child ;
		# if ( $child == 0 ) {
			# open ( STDOUT, ">build.log") or Expire("Build:: cant open stdout $!");
# 			open ( STDERR, ">err.log") or Expire("Build:: cant open stderr $!");
			 # 
			# $com = " /usr/bin/make  build_$no  > build.log" ;
# 			#if ( system ( $com ) != 0 ){ return "$no Error $! can't run $com" ;}
			# exec ($com);  # shouldn't return unless failed
# 			die "Build:: failed to exec $! "; # shouldn't get here, we hope
		# }
# 		Log("Build$no ran $com");
		# # loop
# 		sleep 1800; # builds always take more than 30 minutes
		# my $i ;
# 		for ( $i = 0 ; $i < 45 ; $i++ ) {# i is minutes
			# if ( -e "rdr$no.zImage.initrd" ) {
				# $i = 45 ;
			# }else {
				# sleep 60 ; 
			# }
		# }
# 
 

		if ( -e "rdr$no.zImage.initrd" ) {
			unless (Export("rdr$no.zImage.initrd")){
				Log("DefaultBuild couldn't export $no image - $err");
				$message .= "ERROR: found $no image but Export failed to $storefile_path on $target. $err";
				return "$no Error " .$message;
			}

			my $msg = $message . "\nExported image for ZX$no for version $ver  to $storefile_path on $target. ";
			Send($msg, $audience) or return "$no Error couldn't send $msg to $audience ";
			return "ok" ;
		}else {
			my $log = GetLog() ;
			my $msg = $message . "\nFailed to build $no for $tag for some reason....\n\n $err ....\n\n$log" ;
			Send($msg, $admin) or return "$no Error couldn't send $msg to $audience";
			return "$no Error Failed to build $no for $tag for some reason \n $msg";
		}
	
}


sub Test {
			Log("Test starting.....\n");
		chdir "$buildpath" or return "TEST error $! can't chdirectory to buildpath: $buildpath  " ;
		my $command =  "/bin/rm -rf test test.moved";
			if ( system( $command ) != 0 ) { Expire("TEST can't execute $command`");}
		if (  -d "test.moved" || -d "test") { Expire("TEST can't delete previous build - $err $!");}
		my $comd = " /usr/bin/cvs co test " . ';' . " mv test test.moved" ;
		if ( system ( $comd ) != 0 ){ return "TEST Error $! can't run $comd" ;}
		sleep 5 ;
		chdir "$buildpath/test.moved/prebuilt/etc" or return "TEST Error $! can't chdir to $buildpath/TEST/prebuilt/etc";
		SetVersion() or return "TEST Error couldn't set version string for TEST";
		chdir "$buildpath/test.moved" or return "TEST Error $! can't chdir to $buildpath/test.moved";
		my $com = "/usr/bin/cvs stat; sleep 10 ;  /usr/bin/cvs log -l >> $autolog " ;
		if ( system ( $com ) != 0 ){ return "TEST Error $! can't run $com" ;}
		chdir "$buildpath" ;	# just to be safe
		$command =  "/bin/rm -rf test";
		if ( system( $command ) != 0 ) { Expire("TEST: $! can't run command $command");}
		if ( -d "test" ) { Expire("TEST:  can't delete previous build - test $!");}
		
		$comd = " /usr/bin/cvs co test "  ;
		if (system ( $comd ) != 0 )  { Expire("TEST:  $! can't run command $comd");}
		
		chdir "$buildpath/test" or Expire("TEST:   can't get to the tree $buildpath/test");
		SetVersion() or Expire("TEST: Couldn't set version string");
		
		if ( -e "rdr4900.zImage.initrd-test" ) {
			Export("rdr4900.zImage.initrd-test") or Expire("TEST:  couldn't export 4900 test image ");
			$message .= "TEST: Exported test image for zx4900 to $storefile_path on $target.";
		}else {
			Log("TEST:  didn't find  rdr4900.zImage.initrd-test in test project");
			exit;
		}

	Send($message, $admin) or Log("TEST: Couldn't send $message to $admin");
	
	
}



#///////////// Export ////////////////////#
sub Export {
	my $file = $_[0] ;
	my $ftp;
		Log("Export starting.....\n");

	eval {
		# ftp to target and send files
		$ftp = Net::FTP->new( $target ) or $err .= " Export: couldn't ftp to $target ";
		$ftp->login( $user , $password ) or $err .= "Export:  couldn't login to $target "; 
		$ftp->cwd( $storefile_path ) or $err .= "Export:  couldn't cd to  $storefile_path on $target ";
	};
	if ( @$ ) { $err .= "Export had fatal error ftp'ing to $target -- @$";}
	eval{
		$ftp->put( $file ) or $err .= "Export:  couldn't ftp::put $file  for  $target  $storefile_path ";
	};
	Log("Export got past ftp->put $file\n$err");
	return 1;
	
}

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
 	 else { Expire ( "GetTime got invalid argument $arg");}
 	 
 	 ### to get basic UNIX like timestamp just say $now_string = localtime;  # e.g., "Thu Oct 13 04:54:34 1994
 	 
 	 return $result;
 	 
  }
  
#///////////// CheckTag ////////////////////#
# checks tag against a local log just to see it exists
sub CheckTag {
	if ( $debug > 0) { Log( "\t\t  \n running CheckTag for >>$tag<<  ") ;  }
	# checks tag input against cvs log to make sure its valid
	# @filetext holds the cvs log data
	Log("CheckTag starting.....\n");
	my @cvslog;
	my $logfile = "logfile" ;
	my $logfilepath = $buildpath . "/checktag/$logfile";
	#make tag parameters regex pattern-ready 
	my $ltag = $tag;
	$ltag =~ s/\+/\\+/g ; # have to backslash the plus sign to get a proper pattern
	# go to small rdr tree to check tag
	chdir "$buildpath/checktag";
	my $command = ( "/usr/bin/cvs log Makefile   >  $logfile ");
	
	my $result = system( $command ) ; 
	
	chdir "$buildpath" ;
	sleep 2;
	open (LOGFILEHANDLE, $logfilepath) or Expire("CheckTag Couldn't open $logfilepath "); ;
	while (<LOGFILEHANDLE>){
		push @cvslog , $_;
	}
	close LOGFILEHANDLE;
	 
	if ( @cvslog ) {
		foreach my $line ( @cvslog ){
			if ($line !~ /keyword substitution/){
				if ( $line =~ /$ltag/ ) {  last;}
				
			} else {
				Expire( "Checktag: Your tag is not present - $tag\n");
			}
		}
		unless (defined $password ) { Expire("ARGS:  couldn't get password...$password \n$usage\n\n ");}
		return;
	}
}
	
#///////////// SetVersion ////////////////////#
# sets version string without checking it in
sub SetVersion {
	my $version = qq|
OpenArchitect Branch: $ver    Tag: $tag      Version:$date
	nightly build
Packaging Copyright (C) 2004 Znyx Networks, Inc.
	|;
	open FILEHANDLE, "> version" or Expire("Couldn't open for writing version: $version");
	print FILEHANDLE $version or Expire("Couldn't write to version: $version");
	close FILEHANDLE ;			

}

#///////////// GetLog ////////////////////#
# gets autobuild.log
sub GetLog {
	my (@log,$buildlog);
	open FILEHANDLE, "< " . $autolog or Expire("Couldn't open for reading- log");
	@log = <FILEHANDLE>  or Expire("Couldn't read log");
	close FILEHANDLE ;
	$buildlog = join '\n' , @log ;
	return  $buildlog ;
	
}

#///////////// Send ////////////////////#
# see Mail::Sendmail http://search.cpan.org/author/MIVKOVIC/Mail-Sendmail-0.79/Sendmail.pm
sub Send {
	my $message = $_[0];
	my $mailto = $_[1] ;
	my $subject = "AUTOBUILD for $date" ;
		
###################### safety valve - temporary####################
# prevent stray emails from slipping out to real world
 $mailto = $admin ;
###################### end safety valve -####################
	
	my %mail = ( To      =>  $mailto ,
	             From    => $mailfrom,
	             Subject => $subject ,
	             Message => $message
	            );
	
	sendmail(%mail) or Expire("\nSend::error \tto: $mailto  \tfrom: $mailfrom \nsubj: $subject \nmess: $message \n");	
	
} # end Send


sub Log {
	my (  $text) = (@_) ;

	my $message;	
	my $time = GetTime("stamp");
	my $caller = caller();
	my $header =   qq|\nLOG: $time by: $caller ....................| ;
	if ( $text ) { $message .= qq|\n$text\n |;}
	if ( $message ){
		open FILEHANDLE , ">> " . $autolog or  Send("Log: can't open logfile $message!", $admin) or Expire("Couldn't send log open failure to $admin $message");
		print FILEHANDLE $header ;
		print FILEHANDLE  $message . "\n" or  Send("Log: can't print logfile $header $message!", $admin) or Expire("Couldn't send log print failure to $admin $message");
		close FILEHANDLE ;

	}
			
}

sub CleanLog {
	my $time = GetTime("stamp");
	open FILEHANDLE , "> " . $autolog or die "\nCleanLog: can't open logfile! $message /n<br>";
	print FILEHANDLE  "Starting log $autolog...... $time version $ver for tag $tag \n buildpath $buildpath debug $debug \n" or die "\nCleanLog: couldn't print starting message to  logfile !";
	close FILEHANDLE ;

}


#///////////// Expire ////////////////////#
# use instead of plain die in order to clean up tempdir
sub Expire{
	
	my $message = $_[0] ;
	my $time = GetTime("stamp");
	Log ( $message . "\nERROR: " .$err . "Expired....at $time \n $err $@ \n $!" ) ;
	Send($message . "\nERROR: " .$err . "Expired....at $time \n $err $@ \n $!" , $admin);
	
	die "Expired....at $time \n $err $@ \n $!";
}



1;