#!/usr/bin/perl -w
#
# autobuild.pl
# by John Fisher john.fisher@znyx.com
# supercedes AutoBuild.pl because we just couldnt get the perl script to build
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
use Net::Telnet ();	
require Carp;
use Sys::Hostname;
my $host = hostname(); # acceptable hosts liberace trudyg4
unless ( $host eq "liberace" || $host eq "trudyg4" ) { print "/n ERROR: /n Autobuild.pl--> bad hostname = $host\n "  ; die; }
 
#///////////// set variables ///////////////////#

my $target = "pt" ; # place to put the built images for testing
my $today;  
my $storefile_path = "/ut" ; # add on daily dir each time the loop kicks on
my $storefile_path_today ;
my $buildpath_today ;
my $recentfile_path = "/ut/recent" ;
my $fermatmountpoint = "/ut/fermat_tftpboot_ut_mnt_point" ;
my $buildpath = "/builds/autobuild" ; # add on daily path each loop  ;

my $admin = 'sbo_nightly_admin@znyx.com';
my $audience = 'sbo_nightly@znyx.com'; #'bob.guilfoyle@znyx.com,scott.shannon@znyx.com,' . ',' . $admin ;
my $mailfrom = 'sbo_nightly_admin@znyx.com';

my $mailtoggle = "on" ;

my $aggregated_msg;
my $user = "build" ;
my $password = "val46";
my $autolog ="/tmp/AutoBuild.log" ;
my $err = "ERROR: " ;
# counters to prevent swamping log when there is a catastrophic error
my $logcount = 1;
my $sendcount =1 ;
my $message; # used in various subs

 
#////////////// usage ///////////////////////////#
my $usage = qq|\n===================== USAGE =====================================\n
NAME: \t\tautobuild.pl  
PURPOSE: \tOA is built nightly as a unit test  
\t\tThis script ships off initrd for testing 
\t\tthen sends success or error message.
USAGE: \t\tAutoBuild.pl   <start hour for building (24hr clock)> [< debug level 1-10>] 
\n 
EXAMPLE:\n
autobuild.pl   1 \n

REQUIRES: \tPerl5+ , perl CWD,  CVS \n 

DEBUGGING: 	add a 1-10 as the 3rd argument to invoke trace.
		
=================================================================\n|;
	
#///////////// get parameter ////////////////////#
my $start = $ARGV[0] or  Expire("You must provide a start time...\n$usage\n\n"); # hours on 24 hr clock

my $debug_arg = "none";
$debug_arg = $ARGV[1];
my $debug = 0;


#>>>>>>>>>>>>>>>>>>>>>>>> Main <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<#


# change to the working directory
chdir "$buildpath" or Expire("\nAutoBuild: couldnt chdir to $buildpath");
			#Log ("Autobuild::Main  changed dir to $buildpath") ;

my $date = GetTime("stamp") ;
my $promptdate = GetTime("promptdate") ;
my $buildtime = $date ; # this time, then time this build started, appears in email subject
my $opening_msg = "AutoBuild ADMIN MESSAGE 
began to loop and wait for start time
on $date 
start time is $start " ;
			#Log ("Autobuild::Main  about to send: $message") ;

CleanLog(); 	# empties old log and starts new one, logs initial params too
Send($opening_msg, $admin) ; 
			Log ("Autobuild::Main  sent: $opening_msg") ;

# loop forever testing time of day by the hour
while (1) {

	if ( GetTime("hour") == $start ) { # start the builds
	# if the builds start at say 11:30 pm then they will finish in the next calendar day.
	# nevertheless the today variable is set once when the loop condition succeeds, 
	# so all locations will be consistent
		my $test_msg;
		$today  = TranslateDay();
		$buildtime = GetTime("stamp") ;
		$storefile_path_today = "$storefile_path/$today"  ;
		$buildpath_today  = "$buildpath/$today" ;
		$aggregated_msg = "" ;  # reset message var for new round of nightly builds
		
		if ( $debug_arg && $debug_arg eq "mini-test" ) {
			$debug = 10 ;
			Log( "AutoBuild DEBUG MODE $debug starting TEST AutoBuild at $buildtime  ") ; 
			my $result = Test();
			my $log = GetLog() ;
			$test_msg = "Autobuild ADMIN MESSAGE TEST result= " . $result . " Done with test function $log" ;
			Log ($test_msg) ;
			Send($test_msg, $admin) ;
			Expire("Autobuild test all done...");

		}else {
			if ($debug_arg) {
				if ( $debug_arg !~ /[1-9]/ ){
					#Expire("\n$usage\n\n");
				}
				$debug = $debug_arg;
			 }
			 # all errors  and messaging handled in DefaultDo
			
			if ( $host eq "liberace" ) {

				Log(" Starting normal default build sequence for abs 2010...");
				my $zx20 = DefaultDo("2010", "abs") ;
				unless ( $zx20 eq "ok" ) { Log(" $zx20" ); }

				Log(" Starting normal default build sequence for 322fbranch 5000...");
				my $p8 = DefaultDo("5000", "322fx") ;
				unless ( $p8 eq "ok" ) { Log(" $p8" ); }

				Log(" Starting normal default build sequence for abs 7200base...");
				my $zx1 = DefaultDo("7200base", "abs") ;
				unless ( $zx1 eq "ok" ) { Log(" $zx1" ); }
				
				Log(" Starting normal default build sequence for abs 7300...");
				my $p9 = DefaultDo("7300", "abs") ;
				unless ( $p9 eq "ok" ) { Log(" $p9" ); }
				
				Log(" Starting normal default build sequence for abs 7100...");
				my $r6 = DefaultDo("7100", "abs") ;
				unless ( $r6 eq "ok" ) { Log(" $r6") ; }				
					

				Log(" Starting normal default build sequence for abs 7200fab...");
				my $a1 = DefaultDo("7200fab", "abs") ;
				unless ( $a1 eq "ok" ) { Log(" $a1" ); }

				Log(" Starting normal default build sequence for abs 6000...");
				my $zx6 = DefaultDo("6000", "abs") ;
				unless ( $zx6 eq "ok" ) { Log(" $zx6" ); }


                                Log(" Starting normal default build sequence for abs 4920...");
                                my $zx7 = DefaultDo("4920", "abs") ;
                                unless ( $zx7 eq "ok" ) { Log(" $zx7" ); }


				
				

			}elsif ( $host eq "trudyg4" ) {
				
				
			}
		$logcount  = 1 ; # reset safety counters
		$sendcount = 1 ;
		Send($aggregated_msg, $audience) or return "DefaultDo  Error couldnt send $aggregated_msg to $audience ";
		}
##################################################################################################################################
# use for debugging
# exit ;
#################################################################################################################################
			
	}else {
		
		sleep 600 ; 	# wait for 30 minutes
	}



} # end while

#>>>>>>>>>>>>>>>>>>>>>>>> End Main <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<#

#///////////// Subs Below Here ////////////////////#


# get board number and code branch
# run bash script that checks out and builds, then collect initrd and ship it off to pt
sub DefaultDo {
	my $do_msg;	
	my $no = $_[0] or return "DefaultDo no board number arg!" ;
	my $branch = $_[1] or return "DefaultDo no branch arg!" ;
	my $mapfile = GetMapFileName( "$no" );
	Log("DefaultDo for $branch $no starting.....\n");
	if ($debug_arg ne "test") {
		my $com;
		$com = "/zbin/autobuild_$branch.sh $no &> /dev/null" ;

 		if ( system ( $com ) != 0 ) {
 			Log("DefaultDo couldnt run $com for $branch $no image - $err \n\n");
			$do_msg .= "ERROR: DefaultDo couldnt run $com. $err \n";
			return "DefaultDo $no Error: " .$do_msg;
		}
	}

		my $path = $buildpath_today . '/'. $no . '/' . $branch ;
	chdir "$path" or return "DefaultDo $no $branch error $! can't chdirectory to buildpath: $path " ;
	if ( -e "rdr$no.zImage.initrd" ) {
		unless (Export("rdr$no.zImage.initrd", $branch)eq "ok"){
			Log("DefaultDo couldnt export $branch $no image - $err");
			$do_msg .= "ERROR: DefaultDo found $no image for $branch but Export failed to $storefile_path/$today/$branch on $target. $err";
			return "DefaultDo $no Error: " .$do_msg;
		}
			if ( -e $mapfile ) {
				unless (Export($mapfile, $branch)eq "ok"){
					Log("DefaultDo couldnt export $branch $no $mapfile - $err");
					$do_msg .= "ERROR: DefaultDo found $no $mapfile for $branch but Export failed to $storefile_path/$today/$branch on $target. $err";
				}
			}
			# added to copy 7000 builds from 6000 build automatically
		if ( $no eq "6000") {
			if ( -e "rdr7000.zImage.initrd" ) {
				unless (Export("rdr7000.zImage.initrd", $branch)eq "ok"){
					Log("DefaultDo couldnt export $branch 7000 image - $err");
					$do_msg .= "ERROR: DefaultDo something wrong with 7000 image for $branch Export failed to $storefile_path/$today/$branch on $target. $err";
					return "DefaultDo 7000 Error: " .$do_msg;
				}
			}
		}
			# added to copy 6200 builds from 7200base build automatically
		if ( $no eq "7200base") {
			if ( -e "rdr6200.zImage.initrd" ) {
				unless (Export("rdr6200.zImage.initrd", $branch)eq "ok"){
					Log("DefaultDo couldnt export $branch 6200 image - $err");
					$do_msg .= "ERROR: DefaultDo something wrong with 6200 image for $branch Export failed to $storefile_path/$today/$branch on $target. $err";
					return "DefaultDo 6200 Error: " .$do_msg;
				}
			}
			if ( -e "rdr1900base.zImage.initrd" ) {
				unless (Export("rdr1900base.zImage.initrd", $branch)eq "ok"){
					Log("DefaultDo couldnt export $branch 1900base image - $err");
					$do_msg .= "ERROR: DefaultDo something wrong with 1900base image for $branch Export failed to $storefile_path/$today/$branch on $target. $err";
					return "DefaultDo 1900base Error: " .$do_msg;
				}
			}
		}
		if ( $no eq "7200fab") {
			if ( -e "rdr1900fab.zImage.initrd" ) {
				unless (Export("rdr1900fab.zImage.initrd", $branch)eq "ok"){
					Log("DefaultDo couldnt export $branch 1900fab image - $err");
					$do_msg .= "ERROR: DefaultDo something wrong with 1900fab image for $branch Export failed to $storefile_path/$today/$branch on $target. $err";
					return "DefaultDo 1900fab Error: " .$do_msg;
				}
			}
		}
		my $t = GetTime("stamp") ;
		my $msg =  "\nExported $branch image for ZX$no  to $storefile_path/$today/$branch on $target. ";
		#Send($msg, $admin) or return "DefaultDo $no $branch Error couldnt send $msg to $admin ";
		Log($msg);
		$msg = "\nAutobuild: new $no build available at $target:$storefile_path_today  at $t \n" ;
		#Send($msg, $audience) or return "DefaultDo $no $branch Error couldnt send $msg at $t  to $audience ";
		$aggregated_msg .= $msg ;
		
		Log($msg);
		return "ok" ;
	}else {
		my $t = GetTime("stamp") ;
		my $log = GetLog() ;
		my $msg = $do_msg . "\nDefaultDo Failed to build $no $branch at $t for some reason....\n\n $err ....\n\n$log\n" ;
		Send($msg, $admin) or return "DefaultDo $no Error couldnt send $msg to $admin";
		Log($msg);
		return "DefaultDo $no Error Failed to build $no $branch at $t  for some reason \n $msg\n";
		
	}
		
} # end defaultdo


sub Test {
			Log("Test starting.....\n");
		chdir "$buildpath/testdir" or return "TEST error $! can't chdirectory to buildpath: $buildpath  " ;
		
		my $command =  "/bin/rm -rf test";
					Log("Test ran remove old directory\n");

		if ( system( $command ) != 0 ) { Expire("TEST: $! can't run command $command");}
		if ( -d "test" ) { Expire("TEST:  can't delete previous build - test $!");}
		
		my $comd = " /usr/bin/cvs co test "  ;
					Log("Test ran checkout test project\n");

		if (system ( $comd ) != 0 )  { Expire("TEST:  $! can't run command $comd");}
		
		chdir "$buildpath/test" or Expire("TEST:   can't get to the tree $buildpath/test");
					Log("Test changed dir\n");

		SetVersion() or Expire("TEST: Couldnt set version string");
					Log("Test ran setversion\n");

		
		if ( -e "rdr4900.zImage.initrd-test" ) {
					Log("Test found image\n");

			Export("rdr4900.zImage.initrd-test") or Expire("TEST:  couldnt export 4900 test image ");
			$message .= "TEST: Exported test image for zx4900 to $storefile_path on $target.";
		}else {
			Log("TEST:  didn't find  rdr4900.zImage.initrd-test in test project");
			exit;
		}

	Send($message, $admin) or Log("TEST: Couldnt send $message to $admin");
	
	
}



#///////////// Export ////////////////////#
sub Export {
	my $file = $_[0] ;
	my $branch = $_[1] ;
	my $ftp;
		Log("Export starting..... $file $branch\n");

	eval {
		# ftp to target and send files
		$ftp = Net::FTP->new( $target ) or $err .= " Export: couldnt start ftp to $target \n";
		$ftp->login( $user , $password ) or $err .= "Export:  couldnt login to $target \n"; 
		$ftp->cwd( "$storefile_path/$today/$branch" ) or $err .= "Export:  couldnt cd to  $storefile_path/$today/$branch on $target \n";
		$ftp->binary or $err .= "Export:  couldnt set ftp to binary ";
	};
	if ( @$ ) { 
			$err .= "Export had fatal error setting up ftp to $target -- @$ " ;
			return "bad" ;
			} 
		eval{
			if ( $ftp->put( $file ) ) {
				Log("Export transferred initrd file daily dir ftp->put $file\n");
				# added to cover copying of 7000 from 6000 build
				if ( $file eq "rdr7000.zImage.initrd") { $aggregated_msg .= "\nAutobuild: new 7000 build available at $target:$storefile_path_today   \n" };
				# added to cover copying of 6200 from 7200base build
				if ( $file eq "rdr6200.zImage.initrd") { $aggregated_msg .= "\nAutobuild: new 6200 build available at $target:$storefile_path_today   \n" };
				###  telnet to target to create link files at recentfile_path
				if ( $file =~ /initrd/ ){
					Log(" Now telnetting to pt  to do recent for $file branch=$branch...");
					TelnetConnect("cd $recentfile_path/$branch ; mv $file $file.bk ; ln -s $storefile_path/$today/$branch/$file  $recentfile_path/$branch/$file ; rm $file.bk ") ;
					TelnetConnect("cd $fermatmountpoint/$branch; mv $file $file.bk ; cp -pfd $storefile_path/$today/$branch/$file  $fermatmountpoint/$branch/$file ; chmod 644 $fermatmountpoint/$branch/$file ; rm $file.bk ") ;
					Log(" DEBUG: telnetconnect command= 	cd $fermatmountpoint/$branch; mv $file $file.bk ; cp -pfd $storefile_path/$today/$branch/$file  $fermatmountpoint/$branch/$file ; chmod 644 $fermatmountpoint/$branch/$file ; rm $file.bk ");				
				}
				return "ok";
			}else{ 
				$err .= "Export:  couldnt ftp::put $file branch $branch for  $target  $storefile_path/$today/$branch \n";
				Log("Export ERROR transferring initrd file ftp->put $file for  $target  $storefile_path/$today/$branch  \n$err\n");
				return "bad";
			}

		}
	
}

#////////////// GetMapFileName /////////////////
# we use this complex list because certain builds appear to be different, but share a mapfile
sub GetMapFileName {
	my $model = $_[0] ;  # the platform model number
	my $mapfilename = "badmapfilename";  
	# names can be: System.map.6000-7000.tgz System.map.6150.tgz System.map.7200base.tgz System.map.7200fab.tgz System.map.7100.tgz
	if ( $model eq "rdr6000.zImage.initrd" ) {
		$mapfilename = "System.map.6000-7000.tgz" ;
	}elsif ( $model eq "rdr7000.zImage.initrd" ) {
		$mapfilename = "System.map.6000-7000.tgz" ;
	}else {
		$mapfilename = "System.map.$model.tgz" ;
	}
	return $mapfilename ;
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
	
	
	

#///////////// GetLog ////////////////////#
# gets AutoBuild.log
sub GetLog {
	my (@log,$buildlog);
	open FILEHANDLE, "< " . $autolog or Expire("Couldnt open for reading- log");
	@log = <FILEHANDLE>  or Expire("Couldnt read log");
	close FILEHANDLE ;
	$buildlog = join '\n' , @log ;
	return  $buildlog ;
	
}

#///////////// Send ////////////////////#
# see Mail::Sendmail http://search.cpan.org/author/MIVKOVIC/Mail-Sendmail-0.79/Sendmail.pm
sub Send {
	my $message = $_[0];
	my $mailto = $_[1] ;
	if ( $sendcount > 50 ) { die;}
	my $subject = "AutoBuild of Open Architect for $buildtime" ;
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
		
		sendmail(%mail) || eval { Log("\nAutoBuild::Send::error \tto: $mailto  \tfrom: $mailfrom \nsubj: $subject \nmess: $message \n"); };	
		$sendcount++;
	}else {
		Log("\nAutoBuild::Send::MaILOFF \tto: $mailto  \tfrom: $mailfrom \nsubj: $subject \nmess: $message \n");
	}
	
} # end Send


sub Log {
	my (  $text) = (@_) ;
	if ( $logcount > 500 ) { die;}

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
			# does eval work like a loop when it fails? dunno how to explain email flood...
			if ( $logcount > 500 ) {die;}
			$logcount++;
		};

	}
			
}

sub CleanLog {
	my $time = GetTime("stamp");
	open FILEHANDLE , "> " . $autolog or die "\nCleanLog: can't open logfile! $message /n<br>";
	print FILEHANDLE  "Starting log $autolog...... $time  \n buildpath $buildpath debug $debug \n" or die "\nCleanLog: couldnt print starting message to  logfile !";
	close FILEHANDLE ;

}

# tests using ftp to see if the target is alive
# crude but will work in the case of a crashed server
sub CheckServer {
	my $server = $_[0] or Log (" No servr arg to CheckServer"); 
	my $result = "good";
	eval {
		# ftp to target and send files
		my $ftp = Net::FTP->new( $server ) or $result = "bad";
	};
	return $result;
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

#///////////// TelnetConnect ////////////////////#
sub TelnetConnect {
	my $cmd = $_[0] ;
	my @lines;
	my $t = new Net::Telnet (Timeout => 60, Errmode    => "return", Prompt => '/[\$%#>] $/');



	if ( $t->open("$target") ) {
		$t->login($user, $password);
		
		if ( @lines = $t->cmd("$cmd") ) {
			Log("\nLinked $cmd" );				
		}else{
			Log( "\n UNABLE to Link!  $cmd \n @lines" );
		}
		@lines = $t->close;
		Log( "\n Closing........ \n mesg: @lines" );
	}else {
		Log( "\n Failed to open! $cmd \n " );
	}
}

1;
