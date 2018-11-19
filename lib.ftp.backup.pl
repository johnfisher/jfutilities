#!/usr/bin/perl -w
# 
################### ZNYX NETWORKS ####################			
##### ftp.backup.pl				 #####
##### Check out using the znyx project.		 #####
#
# Purpose:
# copy tgz tarballs from liberace and tiger
# designed to be run nightly

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
my $tracefile = "> /tmp/ftp.backup.log" ;
# Sub to wrap generic trace (see ztts.pm) ; 
# used simply to make code easier to cut&paste and read
sub TT { 
	my $text = "\n" . shift @_ ;
	open FILEHANDLE , $tracefile or die "TracetoFile: can't open path! /n<br>";
				print FILEHANDLE  $text or die "TracetoFile: couldn't print to file, path !";
				close FILEHANDLE ;
			
}

# now start a fresh file
TT( "New run of  ftp.backup.pl ................\n ");
# now switch to append mode
$tracefile = ">> /tmp/ftp.backup.log" ;
# sample usage:   TT(  "$0:<SUBname>  ");
# use to write trace statements to a file, one file per .pl or .cgi file
# set variable $traceflag at the beginning of this file to "on" to enable trace across all files 
# you may need to adjust permissions in the  directory

#######################################################

use strict;
use diagnostics;
use Net::FTP ;
use Shell qw(ls) ;
	


##################################################################################

my @servers = ("liberace" , "tiger" , "cvs-jf" ) ;
my $bkfile_path = "/tmp" ;
my $user = "zbackup" ;
my $password = "kobe8" ;
my $storefile_path = "/zbackups";
my $filespec = ".zbackup.tgz" ;
my $target = "liberace" ; # place to put stuff from this server

Main();



#############################################
sub Main {
	
	chdir $storefile_path or Expire("Main:  couldn't cd to $storefile_path  ");
	foreach my $server ( @servers ) {
		TT(" Copying from $server.....");
		#### connect to servers in list
		my $ftp = Net::FTP->new( $server ) or Expire("Main:  couldn't ftp to $server ");
		$ftp->login( $user , $password ) or Expire("Main:  couldn't login to $server ");
		$ftp->cwd( $bkfile_path ) or Expire("Main:  couldn't cd to /tmp on $server ");

		# get an arrayref to a cleaned list of files that match $filespec
		my $dirtylist =  $ftp->ls()  or Expire("Main:  couldn't ls to get files for  $server ");
		my $list = CleanList( $dirtylist ) or Expire("Main:  couldn't CleanList for  $server ") ;
		

		# ftp::get each file
		foreach my $file ( @$list ) {
			$ftp->get( $file ) or Expire("Main:  couldn't ftp::get $file  for  $server ");
			TT(" Getting $file ");
		}
	}
	
	ExportBK();
			
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
	my @files;
	foreach my $line ( @$list ) {
		
		 if ( $line =~ /zbackup.tgz$/ ) { 
			 push ( @files , $line );  
		 	TT("CleanList: file is $line ");
		 }else { 
			TT("CleanList: ignoring $line ");
		 }
	 }
	 return \@files ;
 } # end sub CleanList
 
 
###############################################
# exports everything in $bkfile_path that matches $filespec to $target/$storefile_path
sub ExportBK {
	
	# get an arrayref to a cleaned list of files that match $filespec
	chdir $bkfile_path ;
	my $dirtylist =    ls() or Expire("Export:  couldn't ls to get files from  $bkfile_path ");
	my @filearray = split /\s/ , $dirtylist ;
	my $list = CleanList( \@filearray ) or Expire("Export:  couldn't CleanList  ") ;
	# ftp to target and send files
	my $ftp = Net::FTP->new( $target ) or Expire(" Export: couldn't ftp to $target ");
	$ftp->login( $user , $password ) or Expire("Export:  couldn't login to $target ");
	$ftp->cwd( $storefile_path ) or Expire("Export:  couldn't cd to /tmp on $target ");
	
	# ftp::get each file
	foreach my $file ( @$list ) {
		$ftp->put( $file ) or Expire("Export:  couldn't ftp::put $file  for  $target ");
		TT("Export: Putting $file ");
	}
} # end sub Export
 