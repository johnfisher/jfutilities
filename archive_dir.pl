#!/usr/bin/perl -w
# 
################### ZNYX NETWORKS ####################			
##### archive_dir.pl				 #####
##### Check out using the zbin project.		 #####
#
# Purpose:
# make and copy tgz tarballs from curent directory

#######################################################

use strict;
use diagnostics;
use Net::FTP ;
#use Mail::Sendmail ;
#use Net::SSH ;
#use Net::SFTP::Recursive;
use Shell qw(ls) ;
no warnings;	
######################################################
### trace and Expireor message handling
my $tracefile = "> /tmp/archive_dir.log" ;
# Sub to wrap generic trace (see ztts.pm) ; 
# used simply to make code easier to cut&paste and read
print "\n TT:Starting  archive-dir.pl.... \n";

TT( "Starting  archive_dir.pl....  \n ");
$tracefile = ">> /tmp/archive_dir.log" ;
sub TT { 
	my $text = "\n" . shift @_ ;
	open FILEHANDLE , $tracefile or die "TracetoFile: can't open path! ";
				print FILEHANDLE  $text or die "TracetoFile: couldn't print to file, path !";
}
###############################################################	



my $user = $ARGV[0] or Expire("ARGS:  couldn't get user \n user password remote-path hostname are required args \n ");
my $password = $ARGV[1] or Expire("ARGS:  couldn't get password ");
my $storefile_path = $ARGV[2] or Expire("ARGS:  couldn't get storefile path ");
my $target = $ARGV[3] or Expire("ARGS:  couldn't get remote server ");

# make a seven day rotation for the path
my $date = localtime(); 
my $day = substr $date, 0, 3 ;  #Get first 3 chars from result
my @dirs;
my @tarballs;
##################### MAIN #####################

CleanList();
#TarballDirs();
#ExportBK();

#############################################
sub Expire {
	my $text = $_[0] ;
	TT( "\n $text" ) ;
	TT( " \n dying.....\n");
	die( $@ ) ;
} # end sub Expire
###############################################
sub CleanList {

	TT("Cleanlist starting...  ");

  opendir HERE, "." or die "opendir: $!";
  foreach my $name (readdir HERE) {
        TT("Cleanlist name = $name   ");
	
    next unless -d $name;
        TT("Cleanlist: found one we like = $name");
	push @dirs, $name ;
  }
  closedir HERE;
	
 } # end sub CleanList
#################################################
# tarball dirs
sub TarballDirs {
	foreach my $name ( @dirs){
		Tarball( $name . ".tgz", $name );
		TT("Tarballed done: name = $name ");
	}

}
#///////////// Tarball ////////////////////#
# call Tarball( dest , src ) 
sub Tarball {
	my $dest = $_[0] ;
	my $src = $_[1] ;
	my $cmd = "tar czf "    . $dest .  " "  . $src ;
		TT("Tarballing: $cmd ");

	system( $cmd ) == 0 or TT "\n********* Expireor ***********\nCouldn't run: $cmd \n****************************";
	

	
} # end sub Tarball
###############################################
# exports tarballed dirs to $target/$storefile_path
sub ExportBK {
	
	my $ftp;
	eval {
		# ftp to target and send files
		$ftp = Net::FTP->new( $target ) or Expire(" Export: couldn't ftp to $target ");
		$ftp->login( $user , $password ) or Expire("Export:  couldn't login to $target ");
		$ftp->cwd( $storefile_path ) or Expire("Export:  couldn't cd to  $storefile_path on $target ");
	};
	if ($@ ) { Expire("ExportBK had fatal Expireor ftp'ing to $target");}
	opendir HERE, "." or die "opendir: $!";
	foreach my $n (readdir HERE) {
		if ( $n =~ /.*\.tgz$/ ) {
			push @tarballs, $n ;
				TT("Export: pushing tarball $n ");

		}
	}
	closedir HERE;

	foreach my $file ( @tarballs ) {
		eval {
				TT("Export: Putting $file ");
			$ftp->put( $file  ) ;
		};
		if ($@ ) { Expire("ExportBK had fatal Expireor ftp getting to $target");}
	}
	

} # end sub Export
 ###############################################
 # securely exports everything in $bkfile_path that matches $remote_filespec to $remote/$storefile_path
 # see http://search.cpan.org/dist/Net-SSH-Perl/lib/Net/SSH/Perl.pm
 #$shell->{sftp}->ls($arg[0] || $shell->{pwd},
 #       sub { print $_[0]->{longname}, "\n" });

 sub SFTPExport {
 	
 	# get an arrayref to a cleaned list of files that match $filespec
 
 	my $dirtylist =    ls() or die(" couldn't ls to get dirs from currdir ");
 	my @filearray = split /\s/ , $dirtylist ;

 	my $list = CleanList( \@filearray, "remote" ) or Expire("ExportSFTP remote:  couldn't CleanList  ") ;
 	my %args = (user => $user,
 			password => $password ,
 			debug => 0) ; # set to one for verbose
 	
 	foreach my $dir ( @dirs ) {
		eval {
			my $sftp = Net::SFTP->new($target, %args) ;
			my $storefile = "something here". '/' . $dir ;
				TT("SFTPExport: Putting $dir  on $target");
			
			$sftp->put($storefile, $dir) ;# can't use "or die" here without filtering the return
				my $timestamp = GetTime("stamp") ;
				TT("SFTPExport: after SFTPing  $dir on $target to /home/zbackup at $timestamp");
		
		};
		if ($@ ) { Expire("SFTPExport had fatal Expireor sftp'ing to $target" . $@);}
	}
	

 	
 } # end SFTPExport
