#!/usr/bin/perl -w
#


use diagnostics;
use strict;
use English ;
require Carp;
use Mail::Sendmail ;
use Sys::Hostname;
use File::Find;
# 
# ZNYX start #######################
use Zbin;
my $zbin = Zbin->New() ;
# ZNYX end   #######################
#
# To use the package- samples:
# $zbin->DumpVar("bugzilla.pm after whoid and query self:" , $self );


my $host = hostname();

my $date = localtime;
my $log =  "/tmp/backup.log" ;
my $dest = "/tmp/dest" ;
my @errmsgs;

my $debug = 1 ;


my $deb = $dest  ;
my $deb_src = "/tmp/src" ;


#///////////// Main Section ////////////////////#
#$zbin->ResetLog("test_bkup.pl on $host starting log at $date ", $log);



#$errmsgs[0] = $zbin->Tarball ( $deb , $deb_src, $log ) ;
#if ( $errmsgs[0] != 0 ) { $zbin->ERR ( " \n test_backup.pl ERROR backing  up $deb_src  $date" , $log ) ;}


#Tarball ( $cpage  , $cpage_src ) ;
#WriteLog ( " \n Backed up $cpage_src  $date" ) ;

#///////////// Set Permissions on tarballs ////////////////////#
opendir DIRHANDLE, $dest ;
my @files = readdir DIRHANDLE ;
closedir DIRHANDLE ;

chown ("1010" , "1010" , "*.tgz" ) ; # 1010 is the uid for zbackup on liberace


if ( scalar @errmsgs > 0 ) { 
	my $errortext = join (',\n ', @errmsgs);
	$zbin->Send ("ERROR(s) from test_bkup.pl on $host " , "number of errors = " . scalar @errmsgs . " \n $errortext", $log );
}


1;
