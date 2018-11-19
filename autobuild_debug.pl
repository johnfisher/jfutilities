#!/usr/bin/perl -w
#
# AutoBuild_debug.pl
# by John Fisher john.fisher@znyx.com
# 
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
use Sys::Hostname;
my $host = hostname(); # acceptable hosts liberace trudyg4
unless (  $host eq "trudyg4" ) { print "/n ERROR: /n Autobuild_debug.pl--> bad hostname = $host\n "  ; die; }
 
#///////////// set variables ///////////////////#

my $target = "pt" ; # place to put the built images for testing
my $today;  
my $storefile_path = "/ut" ; # add on daily dir each time the loop kicks on
my $storefile_path_today ;
my $buildpath_today ;
my $buildpath = "/builds/autobuild/testdir" ; # add on daily path each loop  ;
my $admin = 'admin@pt.znyx.com';
my $audience = 'sbo_test@pt.znyx.com'; #'bob.guilfoyle@znyx.com,scott.shannon@znyx.com,' . ',' . $admin ;
my $mailfrom = 'AutoBuild@pt.znyx.com' ;
my $mailtoggle = "on" ;
my $message;
my $user = "build" ;
my $password = "val46";
my $autolog ="/tmp/AAutoBuild_debug.log" ;
my $err = "ERROR: " ;
# counters to prevent swamping log when there is a catastrophic error
my $logcount = 1;
my $sendcount =1 ;

 
#////////////// usage ///////////////////////////#
my $usage = qq|\n===================== USAGE =====================================\n
NAME: \t\tautobuild.pl  
PURPOSE: \tOA is built nightly as a unit test  
\t\tThis script ships off initrd for testing 
\t\tthen sends success or error message.
USAGE: \t\tAutoBuild_debug.pl   <start hour for building (24hr clock)> [< debug level 1-10>] 
\n 
EXAMPLE:\n
autobuild.pl   1 \n

REQUIRES: \tPerl5+ , perl CWD,  CVS \n 

DEBUGGING: 	add a 1-10 as the 3rd argument to invoke trace.
		
=================================================================\n|;
	
#///////////// get parameter ////////////////////#
my $start = $ARGV[0] or  Expire("You must provide a start time...\n$usage\n\n"); # hours on 24 hr clock

my $debug_arg = $ARGV[1] ;
my $debug = 0;
my $logtext ;


#>>>>>>>>>>>>>>>>>>>>>>>> Main <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<#


# change to the working directory
#chdir "$buildpath" or Expire("\nAutoBuild: couldnt chdir to $buildpath");
			#Log ("Autobuild::Main  changed dir to $buildpath") ;
#$logtext = " after chdir /n";

my $date = GetTime("stamp") ;
my $promptdate = GetTime("promptdate") ;
my $buildtime = $date ; # this time, then time this build started, appears in email subject
$message = "AutoBuild ADMIN MESSAGE 
began to loop and wait for start time
on $date 
start time is $start " ;
			#Log ("Autobuild::Main  about to send: $message") ;
$logtext .= " just before cleanlog /n";
print ( $logtext ) ;


CleanLog(); 	# empties old log and starts new one, logs initial params too

Log ("Autobuild_debug::Main just after cleanlog date = $date promptdate = $promptdate buildtime = $buildtime \n buildpath = $buildpath") ;

#Send($message, $admin) ; 
			#Log ("Autobuild_debug::Main  after sent: $message to: admin = $admin") ;



		my $testmessage;
		$today  = TranslateDay();
		$buildtime = GetTime("stamp") ;
		$storefile_path_today = "$storefile_path/$today"  ;
		$buildpath_today  = "$buildpath/$today" ;
Log ("Autobuild_debug::Main just after cleanlog ");
#today = $today  buildtime = $buildtime \n buildpath_today = $buildpath_today storefile_path_today = $storefile_path_today") ;

		
		if ( $debug_arg eq "test" ) {
			$debug = 10 ;
			Log( "AutoBuild DEBUG inside debug_arg = test MODE = $debug starting TEST AutoBuild at buildtime =$buildtime  ") ; 
			my $result = Test();
			my $log = GetLog() ;
			$testmessage = "Autobuild ADMIN MESSAGE TEST result= " . $result . " Done with test " ;
			Log( "AutoBuild DEBUG inside debug_arg = test before log testmessage ") ; 

			Log ($testmessage) ;
			Log( "AutoBuild DEBUG inside debug_arg = test after testmessage  ") ; 

			Send($testmessage, $admin) ;
			Log( "AutoBuild DEBUG inside debug_arg = test after send testmessage ...about to expire   ") ; 

			Expire("Autobuild_debug expiring at end of debgug_arg = test  test all done...");

		}else {
			die(" died at no debug arg");
		}
		
			
		





#>>>>>>>>>>>>>>>>>>>>>>>> End Main <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<#

#///////////// Subs Below Here ////////////////////#


# get board number and code branch
# run bash script that checks out and builds, then collect initrd and ship it off to pt
sub DefaultDo {
	my $message;	
	my $no = $_[0] or return "DefaultDo no board number arg!" ;
	my $branch = $_[1] or return "DefaultDo no branch arg!" ;
	Log("DefaultDo for $branch $no starting.....\n");
		

	
	my $com = "/zbin/autobuild_$branch.sh $no &> /dev/null" ;
		if ( system ( $com ) != 0 ) {
			Log("DefaultDo couldnt run $com for $branch $no image - $err \n\n");
			$message .= "ERROR: DefaultDo couldnt run $com. $err \n";
			return "DefaultDo $no Error: " .$message;
		}
		my $path = $buildpath_today . '/'. $no . '/' . $branch ;
	chdir "$path" or return "DefaultDo $no $branch error $! can't chdirectory to buildpath: $path " ;
	if ( -e "rdr$no.zImage.initrd" ) {
		unless (Export("rdr$no.zImage.initrd", $branch)eq "ok"){
			Log("DefaultDo couldnt export $branch $no image - $err");
			$message .= "ERROR: DefaultDo found $no image for $branch but Export failed to $storefile_path/$today/$branch on $target. $err";
			return "DefaultDo $no Error: " .$message;
		}

		my $t = GetTime("stamp") ;
		my $msg =  "\nExported $branch image for ZX$no  to $storefile_path/$today/$branch on $target. ";
		Send($msg, $admin) or return "DefaultDo $no $branch Error couldnt send $msg to $admin ";
		Log($msg);
		$msg = "\nAutobuild: new $no build available at $target:$storefile_path_today  at $t \n" ;
		Send($msg, $audience) or return "DefaultDo $no $branch Error couldnt send $msg at $t  to $audience ";
		Log($msg);
		return "ok" ;
	}else {
		my $t = GetTime("stamp") ;
		my $log = GetLog() ;
		my $msg = $message . "\nDefaultDo Failed to build $no $branch at $t for some reason....\n\n $err ....\n\n$log\n" ;
		Send($msg, $admin) or return "DefaultDo $no Error couldnt send $msg to $admin";
		Log($msg);
		return "DefaultDo $no Error Failed to build $no $branch at $t  for some reason \n $msg\n";
		
	}
		
} # end defaultdo


sub Test {
			Log("Test starting.....\n");
		chdir "$buildpath" or return "TEST error $! can't chdirectory to buildpath: $buildpath  " ;
		
		my $command =  "/bin/rm -rf test";
					Log("Test ran remove old directory anmed test \n");

		if ( system( $command ) != 0 ) { Expire("TEST: $! can't run command $command");}
		if ( -d "test" ) { Expire("TEST:  can't delete previous build directory named  test $!");}
		
		my $comd = " /usr/bin/cvs co test "  ;
					Log("Test ran checkout test project\n");

		if (system ( $comd ) != 0 )  { Expire("TEST:  $! can't run command $comd");}
		
		chdir "test" or Expire("TEST:   can't chdir to test");
					Log("Test changed dir\n");

		#SetVersion() or Expire("TEST: Couldnt set version string");
					#Log("Test ran setversion\n");

		
		if ( -e "rdr4900.zImage.initrd-test" ) {
					Log("Test found dummy image file named rdr4900.zImage.initrd-test\n");

			Export("rdr4900.zImage.initrd-test") or Expire("TEST:  couldnt export 4900 test dummy image file");
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
	if ( @$ ) { $err .= "Export had fatal error setting up ftp to $target -- @$"; return "bad" ;}
	eval{
		if ( $ftp->put( $file ) ) {
			Log("Export transferred initrd file ftp->put $file\n");
			return "ok";
		
		}else{ 
			$err .= "Export:  couldnt ftp::put $file branch $branch for  $target  $storefile_path/$today/$branch \n";
			Log("Export ERROR transferring initrd file ftp->put $file\n$err\n");
			return "bad";
		}
	};
	
	
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
 	 
 	 ### to get basic UNIX like timestamp just say $now_string = localtime;  # e.g., "Thu Oct 13 04:54:34 1994
 	 
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
	if ( $logcount > 50 ) { die;}

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
			if ( $logcount > 50) {die;}
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



1;
