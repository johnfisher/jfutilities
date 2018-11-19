#!/usr/bin/perl -w
#
# net-test.pl
# by John Fisher john.fisher@znyx.com

# a test script to see whats up with the network
#################### to do #####################
## make loop save off the files once a day/week, and start over. use cron and die at midnight?
## add mail when it changes a lot
## add ajax loop to htm file so you dont have to F5 it.
## improve logging
## change duration change check from last measurement to avg of last
## change JS dates to magnifying tooltip to save space
## add ability to reset count to 0 to get new baseline after event
###############################################


use diagnostics;
use strict;
use Cwd;
use Net::FTP ;
use Mail::Sendmail ;
use Math::Round qw(nearest);
#use Net::Telnet ();	
require Carp;
use Sys::Hostname;
my $host = hostname(); # acceptable hosts liberace trudyg4

 
#///////////// set variables ///////////////////#



#### VARS safe to change ###############
my $admin = 'john.fisher@znyx.com';
my $sleeptime = 30;  #loop interval in secs
my $warndur = 4 ; # percent change from previous duration
my $mailfrom = "net-test\@$host.sb.znyx.com";	#mail from field
my @goo=qw(google.com);		#a url to test
my @znyx=qw(znyx.com);		#a url to test
my @localdns=qw(10.2.0.2);		#a url to test
my @fremontdns=qw(10.1.1.4);		#a url to test
my @remotedns=qw(8.8.8.8);		#a url to test
my $mailtoggle = "on" ;	# stop mail when testing
# to change log and data file location also must change softlink at /var/www
my $autolog ="/tmp/net-test.log" ;	# path to log; javascript uses a path at /var/www thats a link
my $graphlog="/tmp/net-test.csv" ;	# path to data; javascript uses a path at /var/www thats a link
my $baseline = 10 ; # number of times we write data to array to establish baseline
my $datacnt = 0;	# counting number of data points in current data file
my $datacntlimit = 100;	# limits total data run file size
#################################################################
#### not safe to change below this line!
my $message; # used in various subs
my $count=0; # used in while loop: NOT same as $datacnt
my $printflag = "no";
my $warnflag = "no";
my $warntime = time(); # used to prevent floods of email
my @categories=qw(Categories);
my $gdur = 1; # "1" so we can divide safely
my $zdur = 1;
my $ldur = 1;
my $fdur = 1;
my $rdur = 1;
my $durspreadtime = 100;	# added to data to keep values away from zero in graph
# even when they are close, like .400 ms
#////////////// usage ///////////////////////////#
my $usage = qq|\n===================== USAGE =====================================\n
NAME: \t\tnet-test.pl
PURPOSE: \ttest network
USAGE: \t\tnet-test.pl    [test]\n
\n 
EXAMPLE:\n
net-test.pl  \n

REQUIRES: \tPerl5+ , perl CWD,  CVS \n 

DEBUGGING: 	add any char to invoke test mode.
		
=================================================================\n|;
	
#///////////// get parameter ////////////////////#
my $debug_arg = "none";
$debug_arg = $ARGV[0];


#>>>>>>>>>>>>>>>>>>>>>>>> Main <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<#

my $date = GetTime("stamp") ;
my $promptdate = GetTime("promptdate") ;
my $testtime = $date ; # this time, then time this test started, appears in email subject

CleanLog(); 	# empties old log and starts new one, logs initial params too

# loop forever testing time of day by the hour
while (1) {

		
		my $test_msg;

		my $durtime = GetTime("stamp") ;
print " count = $count last tstamp = $categories[-1] \n";
		
		if ( $debug_arg  ) {
			Log( "net-test DEBUG MODE  starting TEST at $testtime  ") ;

			my $motd = `cat /etc/motd` ;
			Log("TEST_ MOTD: $motd");

			$test_msg = "net-test ADMIN MESSAGE TEST result" ;
			SendPy($test_msg) ;
			Expire("net-test debug test all done...");

		}else {
			#Log(" Starting net-test at $testtime...");
			# 		#### sample csv data schema####
				# 		Categories,10:05:15,10:10:23,10:15:12,10:20:34
				# 		google.com,8,4,6,5
				# 		znyx.com,3,4,2,3
				# 		8.8.8.8,86,76,79,77
				# 		nsa.com,3,16,13,15
			# 		#########################

			# keep global arrays for life of this perl app
			# reprint them to the data file for each loop
			# NOTE first element is the URL ( this makes sense for the print out)

			#get durations $goo[0] etc is the first, unique element, the url...
			$gdur = GetPingTime($goo[0]);
					#print "$gdur durtime $durtime   \n";
			$zdur =  GetPingTime($znyx[0]);   # numbers added to get graph to show separate lines as actual measurements tend to 2000
					#print "$zdur durtime $durtime   \n";
			$fdur =  GetPingTime($fremontdns[0]);
					#print "$fdur durtime $durtime   \n";
			$ldur =  GetPingTime($localdns[0]);
					#print "$ldur durtime $durtime   \n";
			$rdur =  GetPingTime($remotedns[0]);
					#print "$rdur durtime $durtime   \n";




			# check for change in duration, once we have baseline data
			if ( $count > $baseline ) {
				if ( TestDur($goo[-1], $gdur) eq "true"	 )  {
					$printflag = "yes" ;
					Log ("\nWARNING $goo[0] dur = $gdur ,  TIMESTAMP = $durtime \n");

				}elsif ( TestDur( $znyx[-1], $zdur) eq "true" )  {
					$printflag = "yes" ;
					Log ("\nWARNING  $znyx[0] dur = $zdur ,  TIMESTAMP = $durtime \n");

				}elsif ( TestDur($localdns[-1], $ldur) eq "true" )  {
					$printflag = "yes" ;
					Log ("\nWARNING  $localdns[0] = $ldur , TIMESTAMP = $durtime \n");

				}elsif ( TestDur($fremontdns[-1], $fdur) eq "true" )  {
					$printflag = "yes" ;
					Log ("\nWARNING  $fremontdns[0] dur = $fdur , TIMESTAMP = $durtime \n");

				}elsif ( TestDur($remotedns[-1], $rdur) eq "true" )  {
					$printflag = "yes" ;
					Log ("\nWARNING  $remotedns[0] dur = $rdur , TIMESTAMP = $durtime \n");
				}
			}
			# always print if its less than $baseline to get some baseline data; thereafter print if theres a big change
			if ( $count < $baseline  ) {
				PrintData($durtime);	

			}elsif ( $printflag eq "yes" ) {
				PrintData($durtime);
				Warn("ping duration changed!"); # send mail with the log
				$count = 0 ;  # reset to get $baseline number of data points no matter what the warnflag status
			}
		}
		$count++;
		sleep $sleeptime;
		$printflag = "no";  # reset for next measurement

} # end while

#>>>>>>>>>>>>>>>>>>>>>>>> End Main <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<#

#///////////// Subs Below Here ////////////////////#
# Function definition
# sub Average{
#    # get total number of arguments passed.
#    $n = scalar(@_);
#    $sum = 0;
# 
#    foreach $item (@_){
#       $sum += $item;
#    }
#    $average = $sum / $n;
# 
#    return $average;
# }

#///////////// GetTime ////////////////////#

sub TestDur {
	my $olddur = $_[0];
	my $newdur = $_[1];
	my $change;
	# if ping returns 0 1 or 2 due to errors or timeouts
	# avoid divide by zero and text
	if ($newdur == 0){
			return "true";	# just go straight to logging for a zero value
	}
	if ( $olddur =~ /^[0-9]+\.?[0-9]*$/ && $newdur =~ /^[0-9]+\.?[0-9]*$/ ) { # are they both numbers?

		if ($olddur/$newdur > $warndur ){ # is the percent change greater than the filter?
			return "true";
		}
	}else{
			Log("TestDur: PING ERROR: an error message was received: prev. duration - $olddur this duration - $newdur  \n");
			return "true";  # something wrong in data so record it.
	}
		#print " testdur started  count = $count baseline = $baseline olddur $olddur newdur $newdur  \n ";

	return "false";
}

sub GetPingTime {
	my $url = $_[0] or  CGIError(" net-test::GetPingTime got no target argument $_[0]") ;
		#print " getpingtime $arg";
	my $result = `ping -c1  $url | grep time= `;  # gets only the last line from grep output
	# sample output: "3 packets transmitted, 0 received, 100% packet loss, time 2016ms"
			#print "$url result $result \n";

	if ($result   =~ m/time=(\d+\.?\d*)/g ) {
print "GetPingTime: $url  $1 ms\n";
		#my $roundup = nearest(10, $1);   # rounds up to nearest 10
		return $1 + $durspreadtime ;		# arbitrary addition to improve graph and separate 0.n values from zero
	}else {
print "GetPingTime: $url failure error message  $1 \n";
			Log("GetPingTime: PING ERROR - ping returned an error message $result  from $url");
			return 0;  # return an arbitrary large number so that zero results move the graph line to the top, which is "bad"
		}
}


sub Warn {
	my $note = $_[0];
	my $nowtime = time();
	my $c =  $nowtime - $warntime ;
	if ( $c > 3600 ){	# send one per hour
		# sendpy takes subject and uses log as the message
		SendPy ( $note );
		$warntime = time(); # reset 
	}
	return;
}

sub PrintData {
	my $tstamp = $_[0] ;
	# use $datacnt to limit total file size of data files
print "PrintData: datacnt $datacnt\n";
	if ( $datacnt == $datacntlimit ){
		`mv $graphlog  $graphlog.$date`;
		Log("PrintData: moved data csv file to $graphlog.$date");
		$datacnt = 0;
	}else {
		$datacnt++;
	}
	# push on the timestamp
	push(@categories, $tstamp) ;
	# push another onto the data arrays
	push(@goo, $gdur) ;
	push(@znyx, $zdur) ;
	push(@fremontdns, $fdur) ;
	push(@localdns, $ldur) ;
	push(@remotedns, $rdur) ;
	GraphLog() ;
}

#///////////// GetLog ////////////////////#
# gets net-test.log
sub GetLog {
	my (@log,$buildlog);
	open FILEHANDLE, "< " . $autolog or Expire("Couldnt open for reading- log");
	@log = <FILEHANDLE>  or Expire("Couldnt read log");
	close FILEHANDLE ;
	$buildlog = join '\n' , @log ;
	return  $buildlog ;
	
}



sub SendPy {
	my $subject = $_[0];
	Log("SendPy: subject: $subject");
	my $longsubject = '"net-test ' . "  $subject ". '"' ;

	my $pymessage =`/zbin/z-mail.py $longsubject "$mailfrom" "$admin"   "/tmp/net-test.log" `;
	Log("\nSendPy: pymessage: $pymessage\n");
}

sub GraphLog {
		eval {
			open FILEHANDLE , "> " . $graphlog or  Log("GraphLog: can't open graphlogfile $graphlog!") ;
			# print out whole line from array; we use arrays because otherwise we'd have to parse the actual
			# file; this way we just re-write the file each time.
			my $c =  join(",", @categories);
			my $g =  join(",", @goo);	# make one long line
			my $z =  join(",", @znyx);
			my $l =  join(",", @localdns);
			my $r =  join(",", @remotedns);
			my $f =  join(",", @fremontdns);
			print FILEHANDLE  $c . "\n" or  Log("GraphLog: can't print $c graphlogfile  $graphlog!") ;
			print FILEHANDLE  $g . "\n" or  Log("GraphLog: can't print $g graphlogfile  $graphlog!") ;
			print FILEHANDLE  $z . "\n" or  Log("GraphLog: can't print $z graphlogfile  $graphlog!") ;
			print FILEHANDLE  $l . "\n" or  Log("GraphLog: can't print $l graphlogfile  $graphlog!") ;
			print FILEHANDLE  $r . "\n" or  Log("GraphLog: can't print $r graphlogfile  $graphlog!") ;
			print FILEHANDLE  $f  or  Log("GraphLog: can't print $f graphlogfile  $graphlog!") ;
			close FILEHANDLE ;
		};
	return;

}

sub Log {
	my (  $text) = (@_) ;

	my $message;	
	my $time = GetTime("stamp");
	my $caller = caller();
	my $header =   qq|\nLOG: $time by: $caller ....................| ;
	if ( $text ) { $message .= qq|\n$text\n |;}
	if ( $message  ){
	
		eval {
			open FILEHANDLE , ">> " . $autolog or  Send("Log: can't open logfile $message!", $admin) or Expire("Couldnt send log open failure to $admin $message");
			print FILEHANDLE $header ;
			print FILEHANDLE  $message . "\n" or  Send("Log: can't print logfile $header $message!", $admin) or Expire("Couldnt send log print failure to $admin $message");
			close FILEHANDLE ;

		};

	}
			
}

sub CleanLog {
	my $time = GetTime("stamp");
	`echo "" > $autolog ` ;
	open FILEHANDLE , "> " . $autolog or die "\nCleanLog: can't open logfile! $message /n<br>";
	print FILEHANDLE  "Starting log $autolog...... $time   \n" or die "\nCleanLog: couldnt print starting message to  logfile !";
	close FILEHANDLE ;

}

sub GetTime {
 	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
 	my $arg = $_[0] or  CGIError(" Ztts::GetTime got no mode argument $_[0]");
 	$year =~ s/^1/20/ ; # adjust weird year ( 2003 comes as "103" )
	$mon++; # zero-based months - jeez!
 	my $result;

 	 if ( $arg eq "time" ){ $result = $hour . ":" . $min . ":" . $sec ; }
 	 elsif ( $arg eq "day" ) { $result = $wday; }
 	 elsif ( $arg eq "shortstamp" ) { $result = $hour . ":" . $min . ":" . $sec ; }
 	 elsif ( $arg eq "stamp" ) { $result = $mon ."/". $mday. "/" . $year ." ". $hour .":". $min .":". $sec ; }
 	 elsif ( $arg eq "date" ){ $result = $mon . "/" . $mday . "/" . $year ;}
	 elsif ( $arg eq "promptdate" ){ $result = $mon . $mday .  $year ;}
 	 elsif ( $arg eq "hour" ){ $result = $hour ;}
 	 else { Expire ( "GetTime got invalid argument $arg");}

 	 ### to get basic UNIX like timestamp just say $now_string = localtime;  # e.g., Thu Oct 13 04:54:34 1994

 	 return $result;

  }

sub TranslateDay {
	my $d = GetTime("day") ;

	if ( $d == 1 ) { return  "Mon" ; }
	if ( $d == 2 ) { return  "Tue" ; }
	if ( $d == 3 ) { return  "Wed" ; }
	if ( $d == 4 ) { return  "Thu" ; }
	if ( $d == 5 ) { return  "Fri" ; }
	if ( $d == 6 ) { return  "Sat" ; }
	if ( $d == 0)  { return  "Sun" ; }
	else { Expire ("Couldnt translate day d = $d");}

}

#///////////// Expire ////////////////////#
# use instead of plain die in order to clean up tempdir
sub Expire{
	
	my $message = $_[0] ;
	my $time = GetTime("stamp");
	Log ( $message . "\nERROR: Expired....at $time \n  $@ \n " ) ;
	Send($message . "\nERROR: Expired....at $time \n  $@ \n " , $admin);
	
	Log( "Expired....at $time \n $!");
	exit;
}
#///////////// Send ////////////////////#
# see Mail::Sendmail http://search.cpan.org/author/MIVKOVIC/Mail-Sendmail-0.79/Sendmail.pm
sub Send {
	my $message = $_[0];
	my $mailto = $_[1] ;

	my $subject = "net-test of Open Architect for $testtime" ;
###################### safety valve - temporary####################
# prevent stray emails from slipping out to real world
#$mailto = $admin ;
###################### end safety valve -####################
	if ( $mailtoggle eq "on"){
		my %mail = ( To      =>  $mailto ,
			From    => $mailfrom,
			Subject => $subject ,
			Message => $message
			);

		sendmail(%mail) || eval { Log("\nnet-test::Send::error \tto: $mailto  \tfrom: $mailfrom \nsubj: $subject \nmess: $message \n"); };

	}else {
		Log("\nnet-test::Send::MaILOFF \tto: $mailto  \tfrom: $mailfrom \nsubj: $subject \nmess: $message \n");
	}

} # end Send

1;
