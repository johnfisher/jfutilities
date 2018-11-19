#!/usr/bin/perl -w
# 
################### ZNYX NETWORKS ####################			
##### ftp.collector.bk.pl	RENAMED ftp.collector.bk.pl			 #####
##### Check out using the zbin project.		 #####
#
# Purpose:
# copy tgz tarballs from liberace and tiger and pt and monk 
# designed to be run nightly

# call ftp.collector.bk.pl <username> <password> [test | ]  

# Notes:
# Uses naming pattern ($filespec) and target location $bkfile_path to look for files stored on
# @servers . the files are ftp'd over to a location on the local machine 
# IN A 7 DAY WEEKLY MONTHLY ROTATION ON $storefile_path
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
use File::Compare;
# use File::Copy;

use Shell qw(ls) ;
no warnings;	


############################################### ###################################

my @servers = ("liberace.sb.znyx.com" , "tiger.sb.znyx.com" ,  "diz.sb.znyx.com" ,  "pt.sb.znyx.com",   "bobcat.sb.znyx.com") ;
#my @servers = (   "pt" ) ;
my $bkfile_path = '/zbackups_outgoing' ;



my $filespec = ".zbackup" ;
my $remote_filespec = "*remote.zbackup" ; # use command line bash syntax
my $remote_filespec_regex = '.*remote.zbackup' ;
#my $target = "pt" ; # place to put stuff from this server see ExportBK

my $errflag = 0; # if set to 1 than send email to admin
my $errmsg = "";
my $admin = 'john.fisher@znyx.com';
my $outfilepath = "/data/outgoing_nightly_backups" ;
my $unwrap_regex = '\.remote\.zbackup\.tgz'  ;

my $user = $ARGV[0] || "build" || die("ARGS:  couldn't get user ");
my $password = $ARGV[1] || "val46" || die("ARGS:  couldn't get password ");
my $arg = $ARGV[2] ; # optional for testing
my $host = hostname(); # acceptable hosts monk


# make a seven day rotation for the path
my $date = localtime(); 
my $day = substr $date, 0, 3 ;  #Get first 3 chars from result
my $daynumber = GetTime("daynumber"); #get day of month
my $month = GetTime("month");
my $storefile_path = '/data/zbackup/' . $day . '/';
my $older_storefile_path = '/data/zbackup/older_backups' ;
my $thisweekdir = $older_storefile_path . '/week_this';
my $lastweekdir = $older_storefile_path . '/week_last';
my $last1weekdir = $older_storefile_path . '/week_last+1';
my $last2weekdir = $older_storefile_path . '/week_last+2' ; 

### trace and error message handling
my $tracefile = '/tmp/ftp.collector.bk.log' ;

# Sub to wrap generic trace (see ztts.pm) ; 
# used simply to make code easier to cut&paste and read

sub TT { 
	my $text = "\n" . shift @_ ;
	open FILEHANDLE , '>>', $tracefile or print "TracetoFile:TT  can't open path! ...$tracefile... \n";
				print FILEHANDLE  $text or print "TracetoFile: couldn't print to file, path !\n";
				close FILEHANDLE ;			
}
sub restartTT { 
	my $text = "\n" . shift @_ ;
	open FILEHANDLE , '>', $tracefile or print "TracetoFile:retartTT can't open path ...$tracefile...! \n";
				print FILEHANDLE  $text or print "TracetoFile: couldn't print to file, path !\n";
				close FILEHANDLE ;			
}

sub ERR { 
	my $msg =  shift @_ ;
	if ( $errflag == 0 ) { $errflag = 1; }
	$errmsg .= $msg ;
	TT("\n $host ftp_collector ERROR: \n $msg \n ");
	# removed exit			
}

use Sys::Hostname;

unless (  $host eq "monk" ) { print "/n ERROR: /n ftp.collector.bk.pl--> bad hostname = $host\n "  ; die; }
my $startdate = GetTime("stamp") ;
# now start a fresh file
restartTT();
TT( "Starting ftp.collector.bk on $host  ftp.collector.bk.pl $startdate \n ");


if (  $arg eq "test" ) {
	print " \n running tests.....\n";
	# timestamp and restart log
	restartTT();
	my $startdate = GetTime("stamp") ;
	TT( "New TEST run of  ftp.collector.bk.pl $startdate TEST mode\n ");

	#chdir $storefile_path or Expire("Main:  couldn't cd to $storefile_path  ");
	##################### put test code here #############################################

	#
	#  HUH # file::copy doesn't work right or I made a mistake I can;t find
	#



	########################################## end test code ################################################################
		
	
	
	if ( $errflag == 1 ) { 
		print "\nerror message: $errmsg \n";  #send an email with errors to admin
	}else{
		print "\ntest backup complete\n" ;
	}
	print " \n .............done with TEST..................\n";
	exit;
}else {
	Main();
}

#############################################
# get files from servers listed matching filespec and move to local backup dir
# for export to local backup or remote backup server
sub Main {
    GetAllTarballs();
    ProcessWeeklyMonthlyTarballs();


	TT("\n++++++++++++++++++++++++++++++++++++++++++++++\n\t ...............END...........");

	if ( $errflag == 1 && $errmsg ne "" ) { 
		Send( $errmsg ) || exit;  #send an email with errors to admin
	}else{
		Send( "backup complete on $host ") ;
	}


}

#############################################
sub GetAllTarballs {
	chdir $storefile_path or Expire("Main:  couldn't cd to $storefile_path  ");

	foreach my $server ( @servers ) {
		TT(" Copying from $server to $storefile_path");
		my $dirtylist = "";
        my  $ftp ;
		#### connect to servers in list
		eval {
			TT( "Main starting ftp for filelist for $server...");
			$ftp = Net::FTP->new( $server ) or ERR("Main:  couldn't ftp to $server ");
			$ftp->login( $user , $password ) or ERR("Main:  ftp couldn't login to $server ");
			
			$ftp->binary or ERR("Main:  ftp couldn't force to binary on $server "); # added to correct oddball corruption...geez.
			$ftp->cwd( $bkfile_path ) or ERR("Main:  ftp couldn't cd to $bkfile_path  on $server ");

			# get an arrayref to a list of files 
			$dirtylist =  $ftp->ls()  or ERR("Main:  ftp couldn't ls to get files for  $server ");
		};
		if ($@ ) { ERR("Main had fatal error ftp'ing to $server");}
		
		my $list = CleanList( $dirtylist, "all" ) or TT("Main:  couldn't CleanList for  $server ") ;
		
		eval {
			# ftp::get each file
			foreach my $file ( @$list ) {
				
			$ftp->get( $file ) or ERR("Main:  couldn't ftp::get $file  for  $server ");
			TT(" FTP Getting cleanlisted file $file from $server ");
			}
		};
		if ($@ ) { ERR("Main had fatal error ftp getting files from $server");}	
	}



} # end sub GetAllTarballs

#############################################
sub ProcessWeeklyMonthlyTarballs {
# based on day of week, save off to
# weekly or monthly directories
    if ( $day eq "Sun" ) {
	
	## copy all tarballs up a week
	## copy-overwrite not delete because that may save a few
	## deprecated files later
	# copy week_last+1 to last+2
	    system " cp ". $last1weekdir . '/* ' . $last2weekdir ;
	#copy last to last+1
	    system " cp ". $lastweekdir . '/* ' . $last1weekdir ;
	#copy week_this to week_last
	    system " cp ". $thisweekdir . '/* ' . $lastweekdir ;
	# copy day to week_this
	    system " cp ". $storefile_path  . '*.tgz ' . $thisweekdir ;
    }

    if ( $daynumber == 28 ) {
	# copy day to this month's dir
	    system " cp ". $storefile_path  . '*.tgz ' . $month ;
    }


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
	TT("Cleanlist starting...  @$list , $dest ");
	my @files;
	foreach my $line ( @$list ) {
		if ( $dest eq "local" ){
		
			 if ( $line =~ /$filespec/ ) { 
				 push ( @files , $line );  
				TT("CleanList local: file is $line ");
			 }else { 
				TT("CleanList local: ignoring $line ");
			 }
			 
		}elsif ($dest eq "remote" ) {
			if ( $line =~ /$remote_filespec_regex/ ) { 
				push ( @files , $line );  
					TT("CleanList remotefilespec: file is $line ");
			}else { 
					TT("CleanList remotefilespec: regex is $remote_filespec_regex so ignoring $line ");
			}
			
		}elsif ($dest eq "all" ) {
				TT("Cleanlist: dest = $dest line = $line");
			if ( $line =~ /$remote_filespec_regex/ || $line =~ /$filespec/ ) { 
				push ( @files , $line );  
					TT("CleanList all: file is $line ");
			}else { 
					TT("CleanList all: ignoring $line ");
			}
			
		}else {ERR("Cleanlist: got no proper destination arg");}
	 }
	 return \@files ;
 } # end sub CleanList


# # used in conjunction with a cron job that simply calls rsync
# # this sub controls what tarballs get unwrapped so they can be rsynced to Fremont
# sub Unwrap_tarballs {
# 	my $timestamp = GetTime("stamp") ;
# 	chdir $outfilepath ;
# 	system " cp ". $storefile_path . "/cvs*.tgz . " ; # copy only the reposiotry and server files
# 	system " cp ". $storefile_path . "/diz*.tgz . " ; # leave the user files on the backup server
# 	system " cp ". $storefile_path . "/pt*.tgz . " ; # pt files 
# 
# 	my $dirtylist =    ls() or Expire("Unwrap_tarballs:  couldn't ls to get files from  $bkfile_path ");
#         my @filearray = split /\s/ , $dirtylist ;
#         my $list = CleanList( \@filearray, "remote" ) or Expire("Unwrap_tarballs remote:  couldn't CleanList  ") ;
# 
#         foreach my $file ( @$list ) {
#                 eval {
# 			chdir $outfilepath ;
# 			my $dirname = $file ;
# 			$dirname =~ s/$unwrap_regex// ;
# 			unless ( -e $dirname ) { system "mkdir $dirname" ; }
# 			system "mv $file $dirname" ;
# 			chdir $dirname ;
# 			system "tar xzf $file" ;
# 			system " rm -f $file " ;   # remove tarball file so we wont send it via rsync
#                                 TT("Unwarp_tarballs: after unwrapping tarball  $file in $outfilepath at $timestamp");
# 
#                 };
#                 if ($@ ) { 
#                 	ERR("Unwrap_tarballs  had fatal error unwrapping $file in $outfilepath $@");
#                 	 TT("Unwarp_tarballs: had fatal error unwrapping $file in $outfilepath ... error message: $@  ");	
#                 	}
#         }
# 	TT("Unwarp_tarballs: end of sub ");
# }

 

 
 # see Mail::Sendmail http://search.cpan.org/author/MIVKOVIC/Mail-Sendmail-0.79/Sendmail.pm 
 sub Send {
 		TT( "Messages::Send starting...");
 
 	my $mailto = $admin;
 	my $subject;
 	if ( $errflag == 1 ) { $subject = "ERROR message on BACKUP" ;} else { $subject = " Message from Zbackup" ; }
 	my $message = $_[0] or TT( " Send didn't get message argument") ;
 	my $mailfrom = 'zbackup@monk.znyx.com' ;
 
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
 	my $arg = $_[0] or  ERR(" ftp.collector GetTime got no mode argument $_[0]");
 	$year =~ s/^1/20/ ; # adjust weird year ( 2003 comes as "103" )
 	my $result;

 	 if ( $arg eq "time" ){ $result = $hour . ":" . $min . ":" . $sec ; }
 	 elsif ( $arg eq "day" ) { $result = $wday; } 	
 	 elsif ( $arg eq "daynumber" ) { $result = $mday; } 
 	 elsif ( $arg eq "month" ) { 
	      my @abbr = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
	      $result= "$abbr[$mon] "; 
	      }  
 	 elsif ( $arg eq "shortstamp" ) { $result = $hour . "-" . $min . "-" . $sec ; } 	 
 	 elsif ( $arg eq "stamp" ) { $result = $mon ."/". $mday. "/" . $year ." ". $hour .":". $min .":". $sec ; }
 	 elsif ( $arg eq "date" ){ $result = $mon . "/" . $mday . "/" . $year ;}
 	 elsif ( $arg eq "hour" ){ $result = $hour ;} 	 
 	 else { Expire ( "GetTime got invalid argument $arg");}
 	 
 	 ### to get basic UNIX like timestamp just say $now_string = localtime;  # e.g., "Fri Aug 12 14:04:41 2011Fri Aug 12 14:04:41 PDT 2011
 	 
 	 return $result;
 	 
  }
  
1;
