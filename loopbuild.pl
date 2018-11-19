#!/usr/bin/perl -w
#
# LoopBuild.pl
# by John Fisher john.fisher@znyx.com
# supercedes LoopBuild.pl because we just couldn't get the perl script to build
# the projects correctly
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

require Carp;

 
#///////////// set variables ////////////////////#

my $target = "pt" ; # place to built images for testing
my $today;  
my $storefile_path = "/ut" ; # add on daily dir each time the loop kicks on
my $storefile_path_today ;
my $buildpath_today ;
my $buildpath = "/builds/test" ; # add on daily path each loop  ;
my $admin = 'admin@pt.znyx.com';
my $audience = 'sbo_test@pt.znyx.com'; #'bob.guilfoyle@znyx.com,scott.shannon@znyx.com,kevin.robinson@znyx.com' . ',' . $admin ;
my $mailfrom = 'LoopBuild@pt.znyx.com' ;
my $message;
my $user = "build" ;
my $autolog ="/tmp/LoopBuild.log" ;
my $err = "ERROR: " ;

 
#////////////// usage ///////////////////////////#
my $usage = qq|\n===================== USAGE =====================================\n
NAME: \t\tLoopBuild.pl  
PURPOSE: \tOA TEST LOOP BUILD  

USAGE: \t\tLoopBuild.pl  [< debug level 1-10>] 
\n 
EXAMPLE:\n
LoopBuild.pl   1 \n

REQUIRES: \tPerl5+ , perl CWD,  CVS \n 

DEBUGGING: 	add a 1-10 as the 3rd argument to invoke trace.
		
=================================================================\n|;
	
#///////////// get parameter ////////////////////#

my $debug_arg = $ARGV[0] ;
my $debug = 0;


#>>>>>>>>>>>>>>>>>>>>>>>> Main <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<#


# change to the working directory
chdir "$buildpath" or Expire("\nLoopBuild: couldn't chdir to $buildpath");

my $date = GetTime("stamp") ;
my $buildtime = $date ; # this time, then time this build started, appears in email subject


# loop forever testing time of day by the hour
while (1) {

		my $message;
		$today  = GetTime("day");
		$buildtime = GetTime("stamp") ;

		my $r = DefaultDo("5000") ;
		my $t = GetTime("stamp") ;
		if ( $r eq "ok" ) {
			$message = "\nAutobuild: new 5000 build  at $t \n" ;
			Send($message, $audience) ;
		}else {
			$message = "\nAutobuild: Error $r on 5000 build at $t \n" ;
			Send($message, $admin) ;
		}

		#
		my $s = DefaultDo("4920") ;
		$t = GetTime("stamp") ;
		if ($s eq "ok" ){
			$message = "\nAutobuild: new 4920 build   at $t  \n" ;
			Send($message, $audience) ;
		}else {
			$message = "\nAutobuild: Error $s with 4920 build  at $t  \n" ;
			Send($message, $admin) ;

		}
			
} # end while

#>>>>>>>>>>>>>>>>>>>>>>>> End Main <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<#

#///////////// Subs Below Here ////////////////////#



sub DefaultDo {
		
		my $no = $_[0] or return "DefaultDo no board number arg!" ;
		my $com = "/zbin/loopbuild.sh $no &> /dev/null" ;
		if ( system ( $com ) != 0 ) {
			$message .= "ERROR: DefaultDo couldn't run $com. $err";
			return "$no Error " .$message;
		}
		chdir "/builds/test/$no" or return "DefaultDo $no error $! can't chdirectory to buildpath: /builds/test/$no  " ;

		if ( -e "rdr$no.zImage.initrd" ) {
		
			return "ok" ;
		}else {
			my $msg = $message . "\nDefaultDo Failed to build $no  for some reason....\n\n $err " ;
			Send($msg, $admin) or return "DefaultDo $no Error couldn't send $msg to $admin";
			return "DefaultDo $no Error Failed to build $no  for some reason \n $msg";
		}
	
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
 	 elsif ( $arg eq "hour" ){ $result = $hour ;} 	 
 	 else { Expire ( "GetTime got invalid argument $arg");}
 	 
 	 ### to get basic UNIX like timestamp just say $now_string = localtime;  # e.g., "Thu Oct 13 04:54:34 1994
 	 
 	 return $result;
 	 
  }
  

	


#///////////// Send ////////////////////#
# see Mail::Sendmail http://search.cpan.org/author/MIVKOVIC/Mail-Sendmail-0.79/Sendmail.pm
sub Send {
	my $message = $_[0];
	my $mailto = $_[1] ;
	my $subject = "LoopBuild of Open Architect for $buildtime" ;
###################### safety valve - temporary####################
# prevent stray emails from slipping out to real world
$mailto = $admin ;
###################### end safety valve -####################
	
	my %mail = ( To      =>  $mailto ,
	             From    => $mailfrom,
	             Subject => $subject ,
	             Message => $message
	            );
	
	sendmail(%mail) or Log("\nSend::error \tto: $mailto  \tfrom: $mailfrom \nsubj: $subject \nmess: $message \n");	
	
} # end Send




#///////////// Expire ////////////////////#
# use instead of plain die in order to clean up tempdir
sub Expire{
	
	my $message = $_[0] ;
	my $time = GetTime("stamp");
	Send($message . "\nERROR: " .$err . "Expired....at $time \n $err $@ \n $!" , $admin);
	
	die "Expired....at $time \n $err $@ \n $!";
}



1;