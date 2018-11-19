#!/usr/bin/perl -w
# 
################### ZNYX NETWORKS ####################			
##### remote-autobuild.pl				 #####
##### Check out using the zbin project.		 #####
#
# Purpose:
# overcome weird shell isuues in cron by running from
# pt and kicking off the autobuild on liberace
# designed to be run nightly


#######################################################

use strict;
use diagnostics;

use Net::SSH::Perl;

no warnings;	
#######################################################

 ###############################################
 # see http://search.cpan.org/dist/Net-SSH-Perl/lib/Net/SSH/Perl.pm
 # see ~/Net/SSH/Perl/eg  examples remoteinteract2.pl
 
 use Net::SSH::Perl;
 
 my $user = "root" ;
 my $host = "208.1.239.161" ;
 my ($pass) = @ARGV ;
 unless ( $pass ) { die "\n Got no password argument! >>$_[0]<<\n ";}
 
 #my $cmd = "/zbin/autobuild.pl 3.1.2x RDR3_1xbranch+off-RDR312e magic32" ;
 my $cmd1 = "cd /home/build/" ;
 my $cmd2 = "/usr/sbin/chroot /home/build/buildenv/potato /root/.start "  ;
 my $cmd3 = "ls -l /builds" ;
 my $autolog = "/tmp/remote_autobuild.log";

 #####
 
 CleanLog();
 
 #my $ssh = Net::SSH::Perl->new($host, debug => 1, protocol => 2);
 my $ssh = Net::SSH::Perl->new($host, debug => 1, protocol => 2);
 
 $ssh->login($user, $pass);
 
 my($out1, $err1, $exit1) = $ssh->cmd($cmd1);
 Log("\n cmd1 " . $out1 ) if $out1;
 Log ("\n cmd1 " . $err1) if $err1;
 
 
 my($out2, $err2, $exit2) = $ssh->cmd($cmd2);
  Log( "\n cmd2 " . $out2 ) if $out2;
 Log ( "\n cmd2 " . $err2) if $err2;
 
 my($out3, $err3, $exit3) = $ssh->cmd($cmd3);
  Log( "\n cmd3 " . $out3 ) if $out3;
 Log ( "\n cmd3 " . $err3) if $err3;
 
 Log ( "End of remote_autobuild log -  ......................");
 
 #####################  subs #########################
 sub Log {
 	my (  $text) = (@_) ;

	open FILEHANDLE , ">> " . $autolog ;
	print FILEHANDLE  $text ."\n" ;
	close FILEHANDLE ;			
 }
 
 sub CleanLog {
 	open FILEHANDLE , "> " . $autolog or die "\nCleanLog: can't clean logfile!/n<br>";
 	print FILEHANDLE  "Starting log $autolog......\n ";
 	close FILEHANDLE ;
 
}
 
 1;
