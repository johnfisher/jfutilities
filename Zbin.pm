#!/usr/bin/perl -w
# This is the package for re-used subs for Znyx perl scripts.
# Its home is in the zbin CVS project
# to use this add the following to the top of your .pl file in 
# the zbin directory
#
# ZNYX start #######################
#	use Zbin;
#	use diagnostics;
#	my $zbin = Zbin->New() ;
# ZNYX end   #######################
#
# To use the package- samples:
# $zbin->DumpVar("bugzilla.pm after whoid and query self:" , $self );


package Zbin ;   
require Exporter;
 @ISA = qw(Exporter); # namespace stuff from Bugzilla see http://www.perlcircus.org/modules.shtml
 
use strict;
use Mail::Sendmail ;
use Sys::Hostname;
use File::List;
use Time::localtime;
my $host = hostname();
my $debug   ; # set to any value to trigger print to console messages
my $admin = 'john.fisher@znyx.com' ; # who to send error messages to
my $dirsizelimit = 2500000; # about 2 gigs, a workable, but arbitrary choice.. used with du -s ( ls -l gives different block size!)
my $tarball_ext = $host . '.remote.zbackup.tgz' ;
my $err;

use diagnostics -verbose;
	# global constants and variables
use lib ".";

##############################################################################
sub New {
    	my $proto = shift;
  	my $class = ref($proto) || $proto;
  	my $self = { 
  		"first"	=>	undef, 
  		"second"	=>	undef, 
  		};
  	bless ($self, $class);
	return $self
}
#///////////// WriteLog ////////////////////#
sub WriteLog {
	my ( $dummy, $text,  $logfilepath) = (@_) ;
	
			if ( $debug ) { print " \n running WriteLog args: \n arg1 = $text \n arg2 = $logfilepath \n " ; }
	if ( $text && $logfilepath ) {
	
		eval {
			open  ( OUTFILEHANDLE , ">> $logfilepath" ) ; # open for appending with >>
			print  OUTFILEHANDLE "$text\n " ;			
			close OUTFILEHANDLE ;
		};
		if ( $@  ) { return " WriteLog on $host died on failure to write to log \n text: >>>$text<<< \n path: >>>$logfilepath<<< \n ERROR: $@ \n ";}
	}else{
		my $caller = caller();
			if ( $debug ) { print " \n WriteLog got bad arguments caller = $caller text = >>>$text<<< \n\t  path = >>>$logfilepath<<< \n"  ; }	
		return " WriteLog got bad arguments caller = $caller text = >>>$text<<< \n\t  path = >>>$logfilepath<<<" ;

	}
	
			if ( $debug ) { print " \n ran successfully WriteLog  \n arg0 = $text \n " ; }	
	return 0 ;
} # end sub WriteLog


#///////////// ResetLog ////////////////////#
sub ResetLog {
	
			if ( $debug ) { print " \n running ResetLog for $host" ; }
	my $errmsg;
	my ($dummy ,$text, $logfilepath) = (@_);
	if ( $logfilepath ) { 
		
		eval {
			open ( OUTFILEHANDLE , "> $logfilepath" ) ; # open for appending with >>
			print OUTFILEHANDLE "$text \n " ;			
			close OUTFILEHANDLE;
		};
		if ($@ ) { 
			if ( $debug ) { print " \n ZBIN.pm ResetLog returning ERROR for $host $@ ResetLog $text \n on $logfilepath \n error message: $@ \n" ; }
			return "\n Zbin::ResetLog on $host: Error ResetLog $text \n on $logfilepath \n error message: $@ " ;
		}else {
			return 0 ; # everything is OK
		}
		
	}else{		
			if ( $debug ) { print " \n Zbin::ResetLog on $host argument failed: path = >>>$logfilepath<<< \n" ; }
		return "\n Zbin::ResetLog on $host argument failed: path = >>>$logfilepath<<< \n" ;
	}
} # end sub ResetLog

#///////////// Tarball ////////////////////#
# call Tarball( dest , src ) 
sub Tarball {
			if ( $debug ) { print " \n Zbin.pm running Tarball on host = $host" ; }
	my ($dummy, $dest,  $src, $logfilepath) = (@_);
	unless ( $dest &&  $src && $logfilepath ) { print "\n Zbin::Tarball on $host argument failed:  \n dest = >>>$dest<<< src =  >>>$src<<< path = >>>$logfilepath<<< \n" ; exit; }
		
		if ( $debug ) { print " \n running Tarball for dest = $dest and src = $src  " ; }
	my $files = DirsizeFilter("", $src , $logfilepath) ;
	foreach my $file ( @$files) {
		print "\n orig file = $file \n";
		my $trimmedfile = $file;
		$trimmedfile =~ s/^$src\///g ; 
		$trimmedfile =~ s/\//_slash_/g ;
		print "\n shortened file = $trimmedfile \n";
		#$file =~ s/\///g ; 
		#print "\n de-slashed file = $file \n";	
		
		my $cmd = "tar czf " . $dest . '/' . $trimmedfile . '.'  . $tarball_ext . "  " . $src . '/' .   $file;
				if ( $debug ) { print " \n running Tarball for cmd = $cmd dest = $dest file = $file \n " ; }
		eval {
					if ( $debug ) { print " \n ZBIN.pm::Tarball on  $host  running - \n $cmd \n" ; }
			system( $cmd ) ;
		};
		if ($@ ) { 
			ERR("", "Zbin::Tarball Error tarballing $cmd \n error message: $@ ", $logfilepath);
		}else {
			if ( $debug ) { print " \n ZBIN.pm::Tarball ran $cmd on  $host  SUCCESS now calling WriteLog \n" ; }
			WriteLog( "", "Zbin::Tarball tarballed $cmd" ,$logfilepath);
		}	
	}			
} # end sub Tarball

# take a directory and if too large by $dirsizelimit, then break into an array of directories smaller than dirsizelimit
# if any file is larger than dirsizelimit, then send an error message and ignore it
sub DirsizeFilter {
	if ( $debug ) { print " \n Zbin.pm running DirsizeFilter for host = $host" ; }
	my ($dummy,  $src, $logfilepath) = (@_);
	my @results;
	unless  (  $src && $logfilepath ) { print "\n Zbin::DirsizeFilter on $host argument failed:  \n  src =  >>>$src<<< path = >>>$logfilepath<<< \n" ; exit;}
	if ( $debug ) { print " \n Zbin.pm::DirsizeFilter starting to process src = $src" ; }
	#eval {
	my $dirsize;
	$dirsize = `du -s $src` ;  # measured in linux blocks
	$dirsize =~ s/\s$src//g ;  # trim off directory name from result
				if ( $debug ) { print " \n Zbin::DirsizeFilter  dirsize after trim is $dirsize \n" ; }
	if  ( $dirsize < $dirsizelimit ) {
				if ( $debug ) { print " \n Zbin::DirsizeFilter  dirsize is small enough \n" ; }
		WriteLog( "", "Zbin.pm::DirsizeFilter returning small-enough $src", $logfilepath) ; 
		$results[0] = $src ;
		
	}else{
				if ( $debug ) { print " \n Zbin::DirsizeFilter  dirsize is too big trying to break it up \n" ;  }
		
		#my @files = <$src>;
		my $search = new File::List($src)  ;
		#$search->show_only_dirs() ;
		my @filesndirs  = @{ $search->find(".*") } ;
		my $totaldirsize = 0;
		
			if ( $debug ) { print " \n Zbin.pm::DirsizeFilter first file in $src  = $filesndirs[0]" ; }
		foreach my $item (@filesndirs) {
				if ( $debug ) { print " \n Zbin.pm::DirsizeFilter file = $item" ; }
			my $size = `du -s $item`;
			$size =~ s/\s$item//g ;
			$totaldirsize = $totaldirsize + $size ;
			if ( $size > $dirsizelimit) {
				if ( $debug ) { print " \n Zbin.pm::DirsizeFilter file = $item is over dirsizelimit =  $dirsizelimit" ; }				
				ERR( "", "Zbin.pm::DirsizeFilter file = $item on $host at $src is over dirsizelimit =  $dirsizelimit IGNORING $item", $logfilepath);
			
			}elsif( $totaldirsize < $dirsizelimit) {
				if ( $debug ) { print " \n Zbin.pm::DirsizeFilter pushing $item onto results array" ; }
				push @results , $item ;
			}else {
				ERR( "", "Zbin.pm::DirsizeFilter results are over total dir size limit for the tarball file = $item on $host at $src IGNORING $item", $logfilepath);
			}
		
		}
	}
	#};
						
		if ( $debug ) { foreach my $file (@results ) { 	print " \n Zbin.pm::DirsizeFilter returning $file in array" ; 	} }
		foreach my $file (@results ) { 	print " \n Zbin.pm::DirsizeFilter returning $file in array" ; 	}
	return \@results;

}

# the local script should count the errflags, instead of inside ERR
sub ERR { 
			if ( $debug ) { print " \n ZBIN.pm running ERR for $host" ; }
 	my ($dummy, $msg, $logfilepath) = (@_) ;
 	
	if ( $msg && $logfilepath  ) { 
		#Send("", "$host: Zbin.pm ERROR!",  $msg, $logfilepath );
			if ( $debug ) { print " \n ZBIN.pm  ERR on $host sent $msg" ; }	
	}else{
		my $caller = caller();
			if ( $debug ) { print "\n Zbin::ERR on $host argument failed: caller = $caller \n msg = >>>$msg<<< path = >>>$logfilepath<<< \n" ;}
	}
			
}

 # see Mail::Sendmail http://search.cpan.org/author/MIVKOVIC/Mail-Sendmail-0.79/Sendmail.pm
 sub SendAdmin {
 	##  note don't use ERR() in here as that makes a loop. ERR assumes a Send, if Send fails, then logging is only option
 			if ( $debug ) { print " \n ZBIN.pm running SendAdmin for hostname $host \n" ; }
 	my $mailto = $admin;
 	my ($dummy, $subject, $message, $logfilepath) = (@_) ;
 	my $mailfrom = $host . '@znyx.com' ;
 	my %mail;
	if ( $subject && $message && $logfilepath ) { 
	
		%mail = ( To      =>  $mailto ,
			From    => $mailfrom,
			Subject => $subject ,
			Message => $message
			);
	
		eval{
			sendmail(%mail)
		};
		my $rawmail = "Email sent to: " . $mailto . " \nSubject: " . $subject . " \nMessage: " . $message ;
		if ($@ ) { 
			if ( $debug ) { print " \n ZBIN.pm ERROR running SendAdmin for $host sent \n $rawmail \n error: $@" ; }
			WriteLog( "","Zbin::SendAdmin on $host tried and FAILED to send message! $rawmail ", $logfilepath ) ;
			return "Zbin::SendAdmin on $host tried and FAILED to send message! $rawmail " ;
		}else { 
			if ( $debug ) { print " \n ZBIN.pm normal operation running SendAdmin for hostname $host sent this message: \n $rawmail\n" ; }
			my $result = WriteLog( "","Zbin::SendAdmin on $host sent message! $rawmail ", $logfilepath ) ;
			if ( $result != 0 ) {print "WriteLog failed somehow!" ;}
			return 0 ; # everything OK
		}
		
	}else{		

			if ( $debug) {print "Zbin::SendAdmin on $host argument failed: \n subject = >>>$subject<<< \n message = >>>$message<<<< \n path = >>>$logfilepath<<< \n" ;}
		WriteLog( "","Zbin::SendAdmin on $host argument failed: \n subject = >>>$subject<<< \n message = >>>$message<<<< \n path = >>>$logfilepath<<< \n", $logfilepath ) ;
		return "Zbin::SendAdmin on $host argument failed: \n subject = >>>$subject<<< \n message = >>>$message<<<< \n path = >>>$logfilepath<<< \n";
	}
 	
} # end Send

#///////////// GetTime ////////////////////#
sub GetTime {
 my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday) = localtime(time);

print "\n $sec, $min, $hour, $mday, $mon, $year, $wday, $yday \n" ;
 	#my @time = localtime();
 	#foreach my $part ( @time ) { print " at-time = $part \n" ; }
 	my $arg; $arg = $_[1] or  $arg = "stamp"; # stamp is default
 	$year =~ s/^1/20/ ; # adjust weird year ( 2003 comes as "103" )
	$mon++; # zero-based months - jeez!
 	my $result = "Zbin::GetTime failed" ; # in case nothing works

 	 if ( $arg eq "time" ){ $result = $hour . ":" . $min . ":" . $sec ; }
 	 elsif ( $arg eq "day" ) { $result = $wday; } 	 
 	 elsif ( $arg eq "shortstamp" ) { $result = $hour . "-" . $min . "-" . $sec ; } 	 
 	 elsif ( $arg eq "stamp" ) { $result = $mon ."/". $mday. "/" . $year ." ". $hour .":". $min .":". $sec ; }
 	 elsif ( $arg eq "date" ){ $result = $mon . "/" . $mday . "/" . $year ;}
 	 elsif ( $arg eq "hour" ){ $result = $hour ;} 	 
 	 
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

#///////////// Export ////////////////////#
sub FTPExport {
	my $file = $_[0] ;
	my $desthost = $_[1] ;
	my $destpath = $_[2];
	my $user = $_[3] ;
	my $password = $_[4];

	my $ftp;
		WriteLog("FTPExport starting..... $file ");

	eval {
		# ftp to target and send files
		$ftp = Net::FTP->new( $desthost ) or $err .= " Export: couldnt start ftp to $desthost \n";
		$ftp->login( $user , $password ) or $err .= "Export:  couldnt login to $desthost \n"; 
		$ftp->cwd( $destpath ) or $err .= "FTPExport:  couldnt cd to  $destpath on $desthost \n";
		$ftp->binary or $err .= "FTPExport:  couldnt set ftp to binary ";
	};
	if ( @$ ) { $err .= "FTPExport had fatal error setting up ftp to $desthost -- @$"; return "bad" ;} # " funky color-coding fix
	eval{
		if ( $ftp->put( $file ) ) {
			WriteLog("FTPExport transferred  $file\n");
			return "ok";
		
		}else{ 
			$err .= "FTPExport:  couldnt ftp::put $file on $desthost";
			WriteLog("FTPExport ERROR transferring initrd file ftp->put $file\n$err\n");
			return "bad";
		}
	};
	
	
}

1; # required by silly perl packager