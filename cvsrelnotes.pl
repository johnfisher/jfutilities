#!/usr/bin/perl -w
#
# cvsrelnotes.pl
# by John Fisher john.fisher@znyx.com
#
# ASSUMPTIONS:
# Have: cvs, perl 5+; 
# This script is NOT tested on NT or Solaris.
# You must be in topmost directory of cvs tree.
# The directory must be writable.
# You must be logged in to cvs.


use diagnostics;
use strict;
use English ;
use Cwd;
require Carp;
#no warnings;

#///////////// set variables ////////////////////#
my $time = time or die " No time function available?" ; 
my $tempdir = "temp.$time" ;
my $tempdir_saved = "temp.saved" ;
my $logfile = "cvslog.out" ;
my $difffile = "zdiff.out" ;
my $difffilepath = $tempdir . "/" . $difffile ;
my $outputfile = "relnotes.out" ;
my $statfile = "$tempdir/statfile.out" ;
my $taglog = "taglog";
my @filetext = ""; # array to hold text of file
my @difftext = "" ; # array to hold diff file
my $debug = 1;	# set to 1 when debugging
my $thisprogram = $0 ;
my $repospath = "/usr/local/cvs" ; # the path as seen on the repository server; used to strip out local file paths
use Cwd;
my $thisdir = cwd(); # gets the absolute pathname
my $project = "rdr" ;
my $safelogdir = "scripts" ; # cvs log -l is broken! so this means we are running cvs log scripts to get a non=recursing log...
my @errors ; # holds non-fatal error messages
my @added ;
my @changed;
my @removed;


#////////////// usage ///////////////////////////#
my $usage = qq|\n===================== USAGE =====================================\n
NAME: \t\tcvsrelnotes.pl  
PURPOSE: \tExamine repository of the current directory's  
\t\tCVS project and list changes between <tag name> and <tag name>  
USAGE: \t\tcvsrelnotes.pl <mode> <latest tag> <oldest tag>
\n##### YOU MUST  cvs up -d YOUR TREE FIRST! ##### 
##### Currently this script will NOT cross branches:
##### i.e. 1.26 will not be compared with 1.11.3.22
##### only file revs with equal places will be considered
#########################################################\n
WHERE:\t \tmode =  q c v or test
q	\tone line per file listing 
c	\tcustomer report
v	\tverbose listing with log comments and authors 
latest tag=\tnewer CVS release tag 
oldest tag=\tolder CVS release tag
NOTE:  \t\ttags must be on the same branch. Some tags will be rejected.

REQUIRES: \tPerl5+ , perl CWD,  CVS and this script must run in any checked-out cvs tree. \n
To List Tags: \tRun a cvs log Makefile and scroll up.

DEBUGGING: 	add a 1-10 as the 4th argument to invoke trace.
		the script 
		will try to use diff.out in the current directory.
		If there is no $difffile, it will run a HUGE unix-diff
		of the old tree and the new tree.
=================================================================\n|;
	
#///////////// get parameter ////////////////////#
my $mode = $ARGV[0] or  Expire("You must provide a mode and a tag...\n$usage\n\n");
my $latest_tag = $ARGV[1]  or  Expire("You must provide a tag...\n$usage \n\n") ;
my $oldest_tag = $ARGV[2]  or  Expire("You must provide a tag...\n$usage\n \n") ;
$debug = $ARGV[3] ;
my $savedlog ;
my $modename ;
if ($mode eq "v") { $modename = "VERBOSE " ; }
if ($mode eq "c") { $modename = "CUSTOMER " ; }
if ($mode eq "q") { $modename = "QUIET " ; }

#///////////// Report Header ////////////////////#
my $header = qq|\n\n..... Znyx Release Notes $modename Report .....\n|;
if ( $debug > 0) {$header .= qq|\nThis is $thisprogram:  \nstarting in $thisdir.... \n|;}
$header .= qq|\nNEW tag: \t$latest_tag \nOLD tag: \t$oldest_tag\n| ;


#///////////// make tag parameters regex pattern-ready ////////////////////#
my $ltag = $latest_tag;
my $otag = $oldest_tag;
$ltag =~ s/\+/\\+/g ; # have to backslash the plus sign to get a proper pattern
$otag =~ s/\+/\\+/g ;

	#>>>>>>>>>>>>>>>>>>>>>>>> Main <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<#
		if ( $debug > 0) { print "\nCVSRELNOTES DEBUG MODE $debug\nstarting....... \nthis cvs project \t$project \ntempdir \t$tempdir 
	\nlogfile \t$logfile \ndifffilepath \t$difffilepath  
	\noutputfile \t$outputfile \nstatfile \t$statfile \nthisidr \t$thisdir \ndebug level \t$debug\n\n " ; }
#///////////// first create the temp directory ////////////////////#
CreateTempDir() or Expire( "Couldn't mkdir $tempdir");

#///////////// check mode arg ////////////////////#
if ( $mode eq "q" or $mode eq "v" or $mode eq "c") {
	DoDefault() ;

}
elsif ( $mode eq "test" ) {
	Test();
}
else {

	print "Bad mode: You must provide a mode: v, q, c, or test only.!!! \n $usage\n";
	exit;
}

	#///////////// delete temp stuff ////////////////////#
	#CleanUp();

	#>>>>>>>>>>>>>>>>>>>>>>>> End Main <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<#

#///////////// Subs Below Here ////////////////////#

#/////////////// DoDefault /////////////////#
sub DoDefault {
# all non-test formats	
	if ( $debug > 0 ) { print "\nDoDefault starting......  " ; }
	
	#///////////// check tag arg ////////////////////#
	if ( CheckTag() != 1 ) { Expire ("\nDoDefault Bad tag: You must provide  valid tags for this cvs project. $latest_tag and $oldest_tag !!!\n $usage\n") ;}
	
	
	#///////////// get diffs of two cvs trees ////////////////////#
		if ( $debug > 1 ) { print "\nDoDefault running DoDiff  " ; }

	DoDiff();
	# load the arrays with filenames
		if ( $debug > 1 ) { print "\nDoDefault running GetDiffFiles  " ; }
	GetDiffFiles();

	#set vars
	my $spacer1 = "\n...................................................... ";
	my $spacer2 = "......................................................\n" ;
		
	my $sizeofchanged = scalar @changed;
	my $sizeofadded = scalar @added;
	my $sizeofremoved = scalar @removed;
			if ( $debug > 0 ) {print "\nDoDefault sizeof changed: $sizeofchanged sizeof added: $sizeofadded sizeof removed = $sizeofremoved  " ;}
		
	
	my $startpath = cwd() ;
	my $oldcheckpath = $tempdir . '/' . $project . '.' . $oldest_tag . '/'  ;
	my $newcheckpath = $tempdir . '/' . $project . '.' . $latest_tag . '/'  ;
	print $header ;
	print "\nRunning script from startpath = $startpath oldcheckpath = $oldcheckpath newcheckpath = $newcheckpath\n\n" ;
	print "\nChanged Files: $sizeofchanged  Added Files: $sizeofadded   Removed Files: $sizeofremoved\n";
	print "\n\tCHANGED FILES\n=====================================\n";
		
	foreach my $file ( @changed) { 
			if ( $debug > 5 ) { print "\nDoDefault changed: $file  " ; }
			my $flag = "file";
			if ( -d $newcheckpath . $file ) { $flag = "dir" ; } 
		
		if ( $mode eq "c" || $flag eq "dir" ) {
			print "\n$file";
			
		}elsif ( $mode eq "v" ) {
			my $text = GetLogText($file, "changed") ;
			print "\Changed: $file";
			print "\n$text\n$spacer2";
			
		}
	}	
	
	print "\n\n\tADDED FILES\n=====================================\n";
	foreach my $file ( @added) { 
			if ( $debug > 5 ) { print "\nDoDefault added: $file  " ; }
		my $flag = "file";
		if ( -d $newcheckpath . $file ) { $flag = "dir" ; }
		if ( $mode eq "c" || $flag eq "dir") {
			print "\n$file";
			
		}elsif ( $mode eq "v" ) {
			my $text = GetLogText($file, "added") ;
			print "\Added: $file";
			print "\n$text\n$spacer2";
			
		}
	}	
	
	print "\n\n\tREMOVED FILES\n=====================================\n";
	foreach my $file ( @removed) { 
			if ( $debug > 5 ) { print "\nDoDefault removed: $file  " ; }
		my $flag = "file";
		if ( -d $oldcheckpath  . $file ) { $flag = "dir" ; }
			if ( $debug > 5 ) { print "\nDoDefault removed dir check : flag = $flag file =$file  " ; }

		if ( $mode eq "c" || $flag eq "dir") {
			print "\n$file";
			
		}elsif ( $mode eq "v" ) {
			my $text = GetLogText($file, "removed") ;
			print "\Removed: $file";
			print "\n$text\n$spacer2";
			
		}
	}
	
	print "\n\n.......... report finished .........\n";

	
			
} # end sub DoDefault

#///////////// CreateTempDir ////////////////////#
sub CreateTempDir {
	if ( $debug > 0) { print "\t\t  \n running CreateTempDir \n" ; }
	mkdir ( $tempdir , 755   ) or die " Couldn't mkdir $tempdir!" ;

}

#///////////// CleanUp ////////////////////#
sub CleanUp {
	
	#print "\nCleaning up temp directory: $tempdir......... \n" ; 	
	my @cmd = ("rm" , "-rf" , $tempdir ) ;
	system (@cmd)==0 or die " Couldn't rmdir $tempdir!" ;
	if ( @errors > 0 ) {print "\n===================== NON-FATAL ERRORS ==========================\n\n" ;} # print if there are errors
	foreach my $item ( @errors ) {
		
		print "\n===================== ERROR MESSAGE =============================\n" . $item . "\n\n" ;
	}

	print "\n\n..... report finished .....\n \n" ; 
}


#///////////// DoDiff ////////////////////#
# set up unix diffs of two trees; use existing file if possible
# to save time while debugging, create tempdir_saved and keep trees in there
sub DoDiff {
	my $command ;
	if ( $debug > 0) { print "DoDiff ....starting " ; }
	
	# check to see if we left the zdiff.out file around to save time on debug interations
	if (  -e $tempdir_saved . '/' . $difffile ) {
		$tempdir = $tempdir_saved ;  # use the preset temp dir with trees
		
	}else{
			if ( $debug > 0) { print "\nDoDiff got no existing diff file, running CreateDiffTrees " ; }
		CreateDiffTrees();
	}

	$difffilepath = $tempdir . "/" . $difffile ;

			if ( $debug > 4) { print "\nDoDiff finished getting unix diff of two trees \nnow extract data from  $difffilepath" ; }
	
	open (LOGFILEHANDLE, $difffilepath) or Expire("DoDiff Couldn't open $difffilepath "); 
	while (<LOGFILEHANDLE>){
		push  @difftext , $_;
			if ( $debug > 4) { print "\nDoDiff pushing onto difftext array:  $_  " ; }

	}
	close LOGFILEHANDLE;
	
}

#///////////// CreateDiffTrees ////////////////////#
# run cvs co of two trees in the temp directory
sub CreateDiffTrees {
			if ( $debug > 0) { print "  \n CreateDiffTrees starting .... " ; }
	print STDERR "\n\nCVSRELNOTES: checking out two file trees \nRunning diff against two trees\n ........This will take from 20 - 40 minutes......... \n
	\nTo avoid this when running multiple times, save  $difffile to the rdr directory.\n" ; 
	
	chdir $tempdir or Expire(" Couldn't chdir from $thisdir to $tempdir...");
	# checkout latest tree
	my @cmd1 = ("cvs" , "co", "-r", "$latest_tag", "$project") ;
	my $res = system (@cmd1) ;
			if ( $debug > 0) { print "  \n CreateDiffTrees ran $cmd1[0] $cmd1[1] $cmd1[2] $cmd1[3] $cmd1[4]   ...  got >>$res<< " ; }
	# mv $project to unique name
	my @cmd2= ("mv", "$project", "$project.$latest_tag");
	$res = system (@cmd2) ;
			if ( $debug > 0) { print "  \n CreateDiffTrees ran $cmd2[0] $cmd2[1] $cmd2[2] $cmd2[3] $cmd2[4]   ...  got >>$res<< " ; }
	# checkout oldest tree
	my @cmd3 = ("cvs" , "co", "-r", "$oldest_tag", "$project") ;
	$res = system (@cmd3) ;
			if ( $debug > 0) { print "  \n CreateDiffTrees ran $cmd3[0] $cmd3[1] $cmd3[2] $cmd3[3] $cmd3[4]   ...  got >>$res<< " ; }
	# mv $project to unique name
	my @cmd4= ("mv", "$project", "$project.$oldest_tag");
	$res = system (@cmd4) ;
			if ( $debug > 0) { print "  \n CreateDiffTrees ran $cmd4[0] $cmd4[1] $cmd4[2] $cmd4[3] $cmd4[4]   ...  got >>$res<< " ; }
	# diff two trees
	my @cmd = ("diff", " -qr " ," $project.$oldest_tag ", " $project.$latest_tag",  " | ", " grep " , " -v ", " CVS " ," >", " ../$difffilepath" );
	$res = system (@cmd);
			if ( $debug > 0) { print"CreateDiffTrees ran "; foreach my $m ( @cmd){ print "$m";} print"\nCreateDiffTrees ...  got >>$res<< " ; }
	
	chdir ".." ;
	
} # end CreateDiffTrees

#///////////// GetDiffFiles ////////////////////#
# get list of chaged/added/removed files from difffile
sub GetDiffFiles {
	#example line: Only in rdr.311: 311-310d.txt
	#example line: Files rdr.310d/prebuilt/usr/sbin/zsync and rdr.311/prebuilt/usr/sbin/zsync differ
	#example line: Only in rdr.311/prebuilt/usr/sbin: zflash.5000
	
	my $ldir = "$project.$latest_tag";
	my $odir = "$project.$oldest_tag";
	$ldir =~ s/\+/\[\+\]/ ;
	$odir =~ s/\+/\[\+\]/ ;
	unless ( @difftext ) { die " \n No difftext array.....";}
	
					if ( $debug > 4 ) { my $sizeofdtext = scalar @difftext;  print "\nGetDiffFiles ldir is $ldir odir is $odir \n sizeof difftext: $sizeofdtext " ; }
	foreach my $line ( @difftext ) {
					if ( $debug > 4 ) { print "\nGetDiffFiles difftext line: $line \n " ; }
	
			if ( $line =~ /^Only\sin\s$ldir\/(.*):\s(.*)/ ) { # e.g. Only in rdr.RDR3_1_1+RDRABSTRACTbranch/docs: 4900_users_guide.doc
				my $filepath = "$1" . "/" . "$2" ;
				push @added , $filepath ;
					if ( $debug > 5 ) { print "\nGetDiffFiles 1 pushing onto added   $filepath" ; }
				
			}elsif( $line =~ /^Only\sin\s$ldir:\s(.*)/ ) { # e.g. Only in rdr.RDR3_1_1+RDRABSTRACTbranch: txt.doc
				my $filepath = $1 ;
				push @added , $filepath ;
					if ( $debug > 5 ) { print "\nGetDiffFiles  2 pushing onto added $filepath  " ; }
	
			}elsif ( $line =~ /^Only\sin\s$odir:\s(.*)/ ) {
				my $filepath = $1 ;
				push @removed , $filepath ;
					if ( $debug > 5 ) { print "\nGetDiffFiles 3 pushing onto removed $filepath  " ; }
	
			}elsif ( $line =~ /Only in $odir\/(.*):\s(.*)/ ) {
				my $filepath = "$1" . "/" . "$2" ;
				push @removed , $filepath ;
					if ( $debug > 5 ) { print "\nGetDiffFiles 4 pushing onto removed $filepath " ; }
	
			}elsif ( $line =~ /Files\s$odir\/(\S*)\s(and)\s$ldir\/(\S*)\s(differ)$/ ) {
				my $filepath = $1 ;
				push @changed , $filepath ;
					if ( $debug > 5 ) { print "\nGetDiffFiles 5 pushing onto changed $filepath " ; }
	
			}
		}#foreach
			if ( $debug > 0 ) {
				my $sizeofc = scalar @changed;
				my $sizeofa = scalar @added;
				my $sizeofr = scalar @removed;
				#print "\nGetDiffFiles ending- added = $sizeofa lines; changed = $sizeofc lines; removed = $sizeofr lines\n\n  " ; 
			}

	
}#end GetDiffFiles

#///////////// GetLogText ////////////////////#
# get relevant log text for one file
sub GetLogText{
	# takes the cvs file name as argument returns the revision amd log lines from  cvs log
	my $cvsfile = $_[0] || Expire ( "GetLogText Couldn't get arg0 cvsfile ") ;
	my $delta = $_[1] || Expire ( "GetLogText for $cvsfile Couldn't get arg1 mode ") ; # added changed removed
	if ($delta ne "added" && $delta ne "changed" && $delta ne "removed") {Expire ( "GetLogText got bad mode: $delta ") ;}
	
				if ( $debug > 4  ) {print "\nGetLogText: starting... cvsfile $cvsfile ";}
	my $text = "none" ;
	my @logtext = "none";
	my $result = "";
	
	#///// run log on one file , redirecting data to file; read back from file to var 
		 sleep 2 ; 	# slow down with log file to protect from "connection refused" errors...
		 		# when run inside a loop

	system ("cvs log $cvsfile  > $statfile ") == 0 || Expire( "GetLogText: Couldn't cvs log  $cvsfile  \n" );
	open ( STATFILEHANDLE , "< $statfile") || Expire ( "Couldn't open $statfile for $cvsfile \n");
	
	@logtext = <STATFILEHANDLE> ;
	close STATFILEHANDLE ;
	
	
	
	
	#while ( read STATFILEHANDLE , $text, 16384 ) {
						#if ( $debug > 9  ) {print "GetLogText file read of cvs log text: \n $text \n";}
		#if ($text ne "none" ) {
			#@logtext = split /\\n/m, $text ||  Expire("GetLogText for $cvsfile couldn't split logtext array into lines") ;
			
		#}#if
	#}#while
	my $revs = MatchRevs( \@logtext , $delta) || Expire ( "\nGetLogText: Couldn't MatchRevs for $cvsfile  ") ;

			if ( $debug > 4 ) {foreach my $rrr ( @$revs) { print "\n GetLogText-MatchRevs rev = $rrr "; }	}
			
	$text = join m// , @logtext ;	
			if ( $debug > 9  ) {print "\nGetLogText:  changed: joined text: $text  \n";}
			
			
	my @logblocks = split /^----------------------------$/m, $text ||  Expire("GetLogText for $cvsfile couldn't split logtext array into blocks") ;
	
	foreach my $blk ( @logblocks ) {			# go through each block of log text
				if ( $debug > 9) {print "\nGetLogText:  changed: split text blk: $blk  ";}

		if ( $blk  =~ /revision\s(.*)/ ) {		# looking for: revision 1.4.1.2
			my $thisrev = $1 ;
			chomp $thisrev;
			foreach my $rev ( @$revs ){
								if ( $debug > 9 ) {print "\nGetLogText: checking >>$thisrev<< against revs array: >>$rev<<  ";}
				if ( $rev eq $thisrev) {
					 $result .= $blk  ;
					 			if ( $debug > 9 ) {print "\nGetLogText: $thisrev eq $rev result now $result  ";}

				}# if
			}# foreach
		}# if
	} # foreach
			if ( $debug > 5) {print"\nGetLogText for $cvsfile returning $result\n......end returned log text.........\n" ;}

		
	if ( $result ne "") {
		return $result;
		
	}else{ Expire ("GetLogText: Couldn't get log text result for $cvsfile  ") ;}
	


} # end sub GetLogText


#///////////// MatchRevs ////////////////////#
# arg = logtext array returns array of valid revs
sub MatchRevs {
	my $logtext = $_[0];	# array of logtext
	my $delta = $_[1];
	my $lrev = "none";
	my $orev = "none" ;
	my @revs;
				if ( $debug > 0  ) {print "\nMatchRevs starting ......ltag $ltag otag $otag mode $delta \n ";}
	foreach my $text (@$logtext){
		if ( $text =~ /$ltag:\s(.+)$/) {
			$lrev = $1 ;
			
		}elsif($text =~ /$otag:\s(.+)$/){
			$orev = $1 ;
		}
		if ( $text =~ /^keyword substitution.*/ ) { last; }
			if ( $debug > 5 ) {print "\nMatchRevs looking for $ltag or $otag in:\n\t $text\n\t lrev = $lrev orev = $orev ";}
	}
	unless ( $lrev ne "none" || $orev ne "none" ) {return ;}
						if ( $debug > 3 ) {print "\nMatchRevs  got lrev $lrev orev $orev ";}
	my $linecount = scalar @$logtext ;	
	my $i = 0;
		
	if ($delta eq "changed" ){
		while ( @$logtext[$i] !~ /^keyword substitution:.*/){
									if ( $debug > 6 ) {print "\nMatchRevs  changed: matching $ltag in @$logtext[$i] looping until keyword substitution: ";}
			if ( @$logtext[$i] =~ /$ltag:\s(.*)$/) { # if we get down to latest rev tag
				my $rev = $1;
						if ( $debug > 4  ) {print "\n\tMatchRevs  changed: matched $ltag!  logtext= @$logtext[$i] \t....... matched  rev = $rev ";}
				push @revs, $lrev  ;
						if ( $debug > 4  ) {print "\nMatchRevs  changed: pushed lrev $lrev onto atrevs .... $ltag rev= $rev  otag = $otag";}
				$i++;
				while (@$logtext[$i] !~ /$otag:\s.*$/ && @$logtext[$i] !~ /^keyword substitution.*/) {
						if ( $debug > 6  ) {print "\nMatchRevs  changed: while text is not otag $otag logtext= @$logtext[$i] not yet otag = $otag orev = $orev ";}
					
					@$logtext[$i] =~ /.*:\s(.*)$/ ; # get rev number off tag-rev string: RDRCFMbranch+off-RDR310a: 1.1.2.6.0.4
					my $rev = $1;
							if ( $debug > 4  ) {print "\n\tMatchRevs  changed:  got rev- $rev  now sending it to Compare Revs...";}
					if ( CompareRevs( $rev , $lrev, $delta  ) == 1 ) {
						my $flag = "unique";
						foreach my $r ( @revs ) {
							if ( $r eq $rev ) { $flag = "dup" ; }
										if ( $debug > 5  ) {print "\nMatchRevs  changed comparing this rev $rev with array $r - flag = $flag ";}			
						}
						if ( $flag eq "unique" ) { 
							push @revs, $rev  ;
							if ( $debug > 1  ) {print "\nMatchRevs  changed: pushed $rev  ";}
						}
						
							
					}
					$i++;
					if ( @$logtext[$i ] =~ /^keyword substitution.*/ ) { last; } # added for famous monitrc test
					if ( $i == scalar @$logtext ) { die " MatchRevs Runaway Compare Revs changed loop... count = $i";}
				}#while
			}#if
			$i++;
			if ( @$logtext[$i -1] =~ /^keyword substitution.*/ ) { last; } # added for famous monitrc test
			if ( $i == scalar @$logtext ) { die " MatchRevs Runaway changed loop...count = $i";}

		}#while
	}elsif ( $delta eq "added"){
		while ( @$logtext[$i] !~ /keyword\ssubstitution:.*/){
									if ( $debug > 5  ) {print "\nMatchRevs  added: @$logtext[$i] looking for $ltag ";}
			if ( @$logtext[$i] =~ /$ltag:\s(.*)$/) { # if we get down to latest rev tag
				my $rev = $1;
						if ( $debug > 4  ) {print "\nMatchRevs   added @$logtext[$i] matched $ltag got $rev ";}
				push @revs, $rev  ;
				$i++;
				while (@$logtext[$i] !~ /keyword\ssubstitution:.*/) {
						if ( $debug > 4  ) {print "\nMatchRevs  added @$logtext[$i] NOT matched $otag ";}

					@$logtext[$i] =~ /^\w.*:\s(.+)$/ ; # get rev number off tag-rev string: RDRCFMbranch+off-RDR310a: 1.1.2.6.0.4
					my $rev = $1;
						if ( $debug > 4  ) {print "\nMatchRevs  added:  got $rev  now checking it...";}
					if ( CompareRevs( $rev , $lrev, $delta ) == 1) {
						my $flag = "unique";
						foreach my $r ( @revs ) {
							if ( $r eq $rev ) { $flag = "dup" ; }
								if ( $debug > 5  ) {print "\nMatchRevs  added comparing this rev $rev with array $r - flag = $flag ";}
						}
						if ( $flag eq "unique" ) { 
							push @revs, $rev  ;
							if ( $debug > 1  ) {print "\nMatchRevs  added: pushed $rev  ";}
						}
							
					}elsif  ( CompareRevs( $rev , $lrev, $delta  ) == 0 && $debug > 6  ) {print "Comparerevs added FAILED rev = $rev , lrev = $lrev, delta = $delta " ;}
					$i++;
				}#while
			}#if
			if (@$logtext[$i] !~ /keyword\ssubstitution:.*/) { $i++; } # protects against special case of single tag
			if ( $i == scalar @$logtext ) { die " MatchRevs Runaway added loop...";}
		
		}#while

	}elsif ( $delta eq "removed"){
		while (@$logtext[$i] !~ /keyword\ssubstitution:.*/ ){
							if ( $debug > 5  ) {print "\nMatchRevs  removed: @$logtext[$i] looking for $otag ";}			
			if ( @$logtext[$i] =~ /$otag:\s(.*)$/ ){
				 # get rev number off tag-rev string: RDRCFMbranch+off-RDR310a: 1.1.2.6.0.4
				my $rev = $1 ;
						if ( $debug > 4  ) {print "\nMatchRevs  removed:  got rev = $rev  now checking it...";}
				if ( CompareRevs( $rev , $orev, $delta ) ==1 ) {
					my $flag = "unique";
					foreach my $r ( @revs ) {
						if ( $r eq $rev ) { $flag = "dup" ; }
							if ( $debug > 5  ) {print "\nMatchRevs  removed comparing this rev $rev with array $r - flag = $flag ";}
					}
					if ( $flag eq "unique" ) { 
						push @revs, $rev  ;
						if ( $debug > 1  ) {print "\nMatchRevs  removed: pushed $rev  ";}
					}
					$i++;
				}elsif ( $rev eq $orev ) {
					push @revs, $rev  ;
						if ( $debug > 1  ) {print "\nMatchRevs  removed same as orev: pushed $rev  ";}	# case where the only valid rev is the orev tag
				}
			}

			$i++;
			if ( $i == scalar @$logtext ) { die " MatchRevs Runaway removed loop...";}
		}#while

	}
			
		
	if ( scalar @revs > 0 ) {
		return \@revs ;
	}else{ Expire( " MatchRevs Couldn't get any content to return.");}
	
}#MatchRevs

# given a rev taken off the tag, this compares a thisrev to it to see if they are on the same branch
sub CompareRevs {
	my $thisrev = $_[0] || return 0; #Expire ("CompareRevs got no first arg ");
	my $benchmark = $_[1] || Expire ("CompareRevs got no becnhmark arg first arg = $thisrev");
	my $delta = $_[2] || Expire ("CompareRevs got no delta arg first arg = $thisrev second arg = $benchmark");
				if ( $debug > 0  ) {print "\nCompareRevs starting... $thisrev  $benchmark $delta ";}
	
	# test special cases
	if ( $thisrev eq $benchmark  ) { return 0 ; }
	if ( $thisrev eq "1.1" || $thisrev eq "1.1.1.1" ){
		if ($delta eq "changed") { return 0 ;}
		if ($delta eq "added" || $delta eq "removed") { 
				if ( $debug > 3  ) {print "\nCompareRevs returning 1: added|removed initial cvs rev-  $thisrev ";}	
			return 1 ;
		}
		
	}#if
	if ( $thisrev =~ /.*\.0$/ ) { return 0 ;} # start of branch- can't be appropriate
	
	# test 
	my $trev = $thisrev;
	my $brev = $benchmark;
	$trev =~ s/(\.\d{1,3})$// ; # peel off last digits
	$brev =~ s/(\.\d{1,3})$// ;
					if ( $debug > 4  ) {print "\nCompareRevs truncated thisrev: $trev ?eq truncated benchmark: $brev ";}	

	if ( $trev eq $brev ) {
				if ( $debug > 3  ) {print "\nCompareRevs returning 1: branch test PASSED $trev eq $brev for this rev $thisrev";}	
		return 1;
	}else{ 
				if ( $debug > 3  ) {print "\nCompareRevs returning 0: branch test FAILED $trev eq $brev for this rev $thisrev";}	

		return 0 ; 
	}
				if ( $debug > 0  ) {print "\nCompareRevs fell to end : returning 0 : $thisrev  $benchmark $delta ";}	
	return 0 ;
		
} # end CompareRevs





#///////////// CheckTag ////////////////////#
# checks tags against a local log just to see that they exist
sub CheckTag {
	if ( $debug > 0) { print "\t\t  \n running CheckTag for $ltag and $otag " ; }
	# checks tag input against cvs log to make sure its valid
	# @filetext holds the cvs log data
	
	my @cvslog;	
	my $taglogpath = $tempdir . "/" .$taglog ;
	#my @command = ( "cvs " , "log ", $safelogdir ,"> ", $taglogpath);
	my $command = ( "cvs log $safelogdir >  $taglogpath");
	
	#my $result = system( @command ) ; #== 0 or die "Couldn't run: $command ";
	my $result = system( $command ) ; 
				#if ( $debug > 0) { print "  \n CheckTag ran $command[0]$command[1]$command[2]$command[3]$command[4]  ...  got >>$result<< " ; }
		
	sleep 2;
	open (LOGFILEHANDLE, $taglogpath) or Expire("CheckTag Couldn't open $taglogpath "); ;
	while (<LOGFILEHANDLE>){
		push @cvslog , $_;
	}
	close LOGFILEHANDLE;
	 
	if ( @cvslog ) {
		my $cnt = 0;
		my $ttl = @cvslog ;
		my $o =0 ;
		my $l =0 ;
			if ( $debug > 3) { print "\nChecktag ttl = $ttl " ; }
		while ( $cnt <= $ttl ) {
			my $item = $cvslog[$cnt] ;
				if ( $debug > 3) { print "CheckTag log: $item\n" ; }
				
			if ( $item =~ m/$ltag/ ){ # if the ltag is matched in the log text
				# now check to see if there is an otag just following it in this same file
				$l = 1; # ltag exists
				while ( $cnt < $ttl && $cvslog[$cnt] !~ /keyword substitution:/) { # loop through until end of this file's log
					$item = $cvslog[$cnt] ;
							if ( $debug > 3) { print "CheckTag log: $item\n" ; }

					if ( $item =~ m/$otag/ ){ 

						return 1; # tags OK
					}
					$cnt++;
					if ( $debug > 5) { print "CheckTag looking for OTAG -count $cnt\n" ; }
				}
					
					
				
			}elsif ( $item =~ m/$otag/  ){ # if the old tag is matched in the log text, but not the latest flag yet-error?
				$o =1; # otag exists
				
							if ( $debug > 3) { print "CheckTag log: $item\n" ; }

				while ( $cnt < $ttl && $cvslog[$cnt] !~ /keyword substitution:/) { # loop through until end of this file's log
							if ( $debug > 3) { print "CheckTag log: $item\n" ; }
					$item = $cvslog[$cnt] ;

					if ( $item =~ m/$ltag/ ){ 
						print "\n\nWARNING: your tags are entered in reversed chronological order. \nI switched them and continued...\n\n";
						my $holder = $ltag ;
						$ltag = $otag;
						$otag = $holder;
						return 1 ;
					}
					$cnt++;
					if ( $debug > 5) { print "CheckTag looking for LTAG -count $cnt\n" ; }
				}
			}
			$cnt++;
					if ( $debug > 3) { print "CheckTag new LOOP -count $cnt\n" ; }			
			if ( $cnt == $ttl ) { # we have run through the whole log and never got both tags in one file's log
				if ( $o + $l == 2 ) { # both are positive
					print "\nWARNING: there are no files with both tags.\nThis MAY be valid, likely NOT.\nContinuing ...\n\n";
					return 1;
					
				}elsif( $o == 0 && $l == 1){Expire( "Checktag Your oldest tag is not present on any file. $oldest_tag");
				
				}elsif( $o == 1 && $l == 0){Expire( "Checktag Your latest tag is not present on any file. $latest_tag");
				
				}elsif( $o + $l == 0){Expire( "Checktag Your tags are not present on any file. \n$latest_tag $oldest_tag\n");}
				
				                                            
			}
		}
		
	}else{
		Expire (" Checktag: can't find a log output file.");
	}
		if ( $debug > 0) { print "\nCheckTag returning negative  for $ltag and $otag\n" ; }	
	Expire("\n\nFatal Error in CheckTag.\n\n");
			
} # end  CheckTag			




#Cleans up paths like "    Repository revision: 1.1.1.1 usr/local/cvs/reltest/bdir/Attic/thingB,v"
#to be: "bdir/thingB"
#and "/usr/local/cvs/reltest/subdir/subA,v"   to be : "subdir/subA"
# only works from the top of the tree!
sub GetCVSFilePath {
	my $cvsfile = $_[0] ;
		if ( $debug > 0) { print "GetPath: incoming arg $cvsfile \n";}
	$cvsfile =~ /RCS file:\s(.+),v$/ ; # isolate path stuff 
	$cvsfile = $1; # get path
		if ( $debug > 0) { print "GetPath: rev strip: $cvsfile \n";}
	$cvsfile =~ s/$repospath//  ; # strip off repos path and trailing rcs file extension
		if ( $debug > 0) { print "GetPath: repo strip: $cvsfile \n";}
	$cvsfile =~ s/^\/\w{1,}\///g ; # strip off modulename "rdr" for instance
		if ( $debug > 0) { print "GetPath: module strip: $cvsfile \n";}	
	if ( $cvsfile =~ /Attic/ ) { $cvsfile =~ s/Attic\/// }; # strip /Attic out of path
		if ( $debug > 0) { print "GetPath: attic strip: $cvsfile \n";}
	#$cvsfile =~ s/^\w+\/// ; # cut off first dir (thisdir) 
	my $temp = $thisdir ;
	$temp =~ /.+\/(.+)$/ ; # pick off last directory
	my $lastdir = $1 ;
	$temp =~ s/\/$lastdir// ; # remove last directory
	while ( $cvsfile =~ s/$lastdir\/// ){
		$temp =~ /.+\/(.+)$/ ; # pick off last directory
		$lastdir = $1 ;
		$temp =~ s/\/$lastdir// ; # remove last directory
		if ( $debug > 0) { print "GetPath: while loop-  temp = $temp lastdir = $lastdir cvsfile = $cvsfile \n";}
	}
	
	
	
		if ( $debug > 0) { print "GetPath: after thisdir strip, returning: $cvsfile \n";}

	return $cvsfile;
}

# gets the relative path from the starting directory down to the file
# so if the absolute path is "/data/work/rdr.abstract/sources/zdriver"
# the cvs path will be " RCS file: /usr/local/cvs/rdr/sources/zdriver/pdk/Makefile,v"
# and this will return "sources/zdriver" indicating where we are relative to the top of tree
sub GetStartPath {
		if ( $debug > 0) {print "\nGetStartPath: starting ....  \n";}
	my $cnt = 0 ;
	my $limit = 10000 ;
	my $result ;
	# get a cvs path from the log, the first one will be complete and good enough to use...
	while ($cnt < $limit){
			if ( $debug > 0) {print "\nGetStartPath: LOOPcnt  $filetext[$cnt]  \n";}
			# look for next line with "Working file" in it 
			if ($filetext[$cnt] =~ /RCS file:/  ) { # found a new file
	
				# found a working file listing, now get data- file name first
				$result =  $filetext[$cnt]  ; 
				my $file = $filetext[$cnt + 1]  ; # get file name form working file: line
				$file =~ s/Working file:\s{1,}//g ;
				$file =~ s/\n// ; # trim off newlines if there
				if ($file =~ /\./ ) { $file =~ s/\./\\./ ; } # if there is a dot, add a backslash
						if ( $debug > 0) { print "GetStartPath: file = >>$file<< " ;}
				$result =~ /RCS file:\s(.+),v$/ ; # isolate path stuff 
				$result = $1; # get path
						if ( $debug > 0) { print "GetStartPath: dollar 1 extract: $result \n";}
				#if ( $result =~ /\./ ) { $result =~ s/\./\\./  ; } # backslash the dots
						if ( $debug > 0) { print "GetStartPath: rev strip - dot backlsh: $result \n";}
				$result =~ s/$file// ; # strip off filename
				$result =~ s/$repospath//  ; # strip off repos path and trailing rcs file extension
				$result =~ s/^\/\w{1,}\///g ; # strip off modulename "rdr" for instance
					#$result =~ s/\/w{1,}$//g ; # strip off filename
						if ( $debug > 0) {print "\nGetStartPath: returning $result  \n";}
				if ( $result !~ /\w/ ) { $result = "top of the tree ...";} # if there are no characters left, then this must be the top
				return $result;
			}
			$cnt++;
			if ( $cnt == $limit - 1 ){ Expire ("GetStartPath never found a cvs filepath.")};
	} # end while
	
	
	
} # end GetStartPath			
			

sub Test {
	$debug = 10 ;
	
	Expire("Test module not built yet.");
	
} # end Test



sub TestCompRevs{
	print "\n Testing Comparerevs ...........\n" ;
		my $result = CompareRevs ("Makefile" , "1.8" , "1.3" ) ;
		print "\n Compare 1.8 to 1.3 : \tresult should be 1 \tresult = $result \n";
		$result = "null" ;
		
		$result = CompareRevs ("Makefile" , "1.1" , "1.1.1.1" ) ;
		print "\n Compare 1.1 to 1.1.1.1 : \tresult should be 0 \tresult = $result \n";
		$result = "null" ;	
			
		$result = CompareRevs ("Makefile" , "1.2" , "1.1.1.1" ) ;
		print "\n Compare 1.2 to 1.1.1.1 : \tresult should be 1 \tresult = $result \n";
		$result = "null" ;	
			
		$result = CompareRevs ("Makefile" , "1.2" , "1.3" ) ;
		print "\n Compare 1.2 to 1.3 : \tresult should be 0 \tresult = $result \n";
		$result = "null" ;
		
		$result = CompareRevs ("Makefile" , "1.1.1.2" , "1.1" ) ;
		print "\n Compare 1.1.1.2 to 1.1 : \tresult should be 1 \tresult = $result \n";
		$result = "null" ;
		
		$result = CompareRevs ("Makefile" , "1.1.1.2" , "1.1.1.2" ) ;
		print "\n Compare 1.8 to 1.3 : \tresult should be 0 \tresult = $result \n";
		$result = "null" ;
		
		$result = CompareRevs ("Makefile" , "1.9" , "1.1.1.2.1.2" ) ;
		print "\n Compare 1.9 to 1.1.1.2.1.2 : \tresult should be 1 \tresult = $result \n";
		$result = "null" ;
			
		$result = CompareRevs ("Makefile" , "1.1" , "1.1.1.2.1.2" ) ;
		print "\n Compare 1.1 to 1.1.1.2.1.2 : \tresult should be 0 \tresult = $result \n";
	$result = "null" ;
}

sub TestChkTag {
	my $logcommand = (  "cvs log -l > ". $tempdir . "/" . $logfile)	 ;
		
	system( $logcommand ) == 0 or die "Couldn't run: $logcommand ";
	my $logfilepath = $tempdir . "/" . $logfile ;
		
	open (LOGFILEHANDLE, $logfilepath) ;
	while (<LOGFILEHANDLE>){
		#print " puishing $_";
		push  @filetext , $_;
	}
	close LOGFILEHANDLE;
	print "\n Testing checktag your entries were $latest_tag and $oldest_tag\n";
	$debug =1;
	#$logcommand = (  "cat ". $tempdir . "/" . $logfile . " | grep " . $otag)	 ;
	#print "\n running $logcommand.....\n";		
	#system( $logcommand ) == 0 or die "Couldn't run: $logcommand ";
	if ( CheckTag() == 0 ){
		print " \n CheckTag did not find matching tag names in the cvs log for both tags $latest_tag and $oldest_tag...\n";
	}else{ print " \n CheckTag found matches for $latest_tag and $oldest_tag.\n";}
	
	
}
#///////////// Expire ////////////////////#
# use instead of plain die in order to clean up tempdir
sub Expire{
	
	my $message = $_[0] ;
	print  "\n\n===================== FATAL ERROR! =============================\n\n" .$message . "\n\ncleaning up temp files....\n" ;
	#if ( $debug < 1) {CleanUp();}
	
	die;
}

#///////////// ErrorMessage ////////////////////#
# use for non fatal errors
# prints error, continues, saves message and re-prints at end.
sub ErrorMessage{
	
	my $message = $_[0] ;
	print  "\n\n===================== ERROR MESSAGE =============================\n\n" .$message . "\n\n===================== CONTINUING... ======================\n" ;
	push ( @errors, $message ) ;
	
	
}
1;






