#!/usr/bin/perl -w
# autobuild_watchdog.pl
# by John Fisher john.fisher@znyx.com
# watches to see if there is an autobuild running
# run from cron. If no autobuild running then email
#
# ASSUMPTIONS:
# Have: cvs, perl 5+; 


# The following are arrays for the hour, month, and day of the week


use diagnostics;
use strict;
use Cwd;

use Mail::Sendmail ;

require Carp;
use Sys::Hostname;
my $host = hostname(); # acceptable hosts liberace trudyg4
unless ( $host eq "liberace" || $host eq "trudyg4" ) { print "/n ERROR: /n autobuild_watchdog.pl--> bad hostname = $host\n "  ; die; }
 
#///////////// set variables ///////////////////#

my $admin = 'john.fisher@znyx.com';
my $audience = 'john@jpfisher.net'; #'bob.guilfoyle@znyx.com,scott.shannon@znyx.com,' . ',' . $admin ;
my $mailfrom = 'autobuild_watchdog@' . $host . '.znyx.com' ;
my $mailtoggle = "on" ;

my $autolog ="/tmp/autobuild_watchdog.log" ;



#sleep 180 ;

#////////////// usage ///////////////////////////#
my $usage = qq|\n===================== USAGE =====================================\n
NAME: \t\tautobuild_watchdog.pl  
PURPOSE: \t runs from cron to watchdog autobuild.pl
USAGE: \t\t autobuild_watchdog.pl    	
=================================================================\n|;

# 
# ZNYX start #######################
use Zbin;
my $zbin = Zbin->New() ;
# ZNYX end   #######################
#
# To use the package- samples:
# $zbin->DumpVar("bugzilla.pm after whoid and query self:" , $self );



my $debug = $ARGV[1] ; # optional set to some integer or character
my $starttime = GetTime("stamp");

$zbin->ResetLog("Starting autobuild_watchdog.pl on $host at $starttime ", "$autolog"); 	# empties old log and starts new one, 

my $message = " The looping autobuild script is not running on $host. There will be no nightly build tonight from this host.

(However, the other nightly build host may automatically do the whole build more slowly. )

To restart the process on $host, ssh in as user build, and run /zbin/autobuild.pl <space> <24 hr clock hour> 
Where 24 hr clock hour is the hour in which to start the nightly build, usually 17.

Note: you cannot run autobuild.pl in the background, nor by cron directly." ;


#>>>>>>>>>>>>>>>>>>>>>>>> Main <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<#
	if ($debug){ print"\n starting... start = $starttime \n";}


	my $psdata = ` ps ax | grep autobuild | grep -v grep` ; # -v removes the record of this grep from ps output
	my $thistime = GetTime("stamp");
	if ($debug){ print"\n ps data returned \n >>>>$psdata<<<< \n";}

	if ($psdata =~ /autobuild/ ) {
		
		$zbin->WriteLog("$thistime psdata matched - $psdata ", $autolog);

		# do nothing
		if ($debug){ print"\n doing nothing \n";}

	}else {
		if ($debug){ print"\n sending mail message \n";}
		$zbin->WriteLog("$thistime psadata did not match sending email ", $autolog);
		$zbin->SendAdmin ("AUTOBUILD NOT RUNNING on $host at $thistime ", $message , $autolog );

	}



#################### subs ##############################

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
	 elsif ( $arg eq "promptdate" ){ $result = $mon . $mday .  $year ;}
 	 elsif ( $arg eq "hour" ){ $result = $hour ;} 	 
 	 else { Expire ( "GetTime got invalid argument $arg");}
 	 
 	 ### to get basic UNIX like timestamp just say $now_string = localtime;  # e.g., Thu Oct 13 04:54:34 1994
 	 
 	 return $result;
 	 
  }


1;
