#!/usr/bin/perl -w
#use diagnostics;
use CGI::Carp ;
my @files;
my @vars;
my ($FH, $FFH);

print " starting \n";




open (FFH , "<vars.txt" ) or die "Couldn't open vars";
while (<FFH>){
	push @vars, $_ or die " Couldn't push $_ from vars";
}

close FFH;
my $ct = 1;

open (FH, "<./wonderdesk.cgi") or die "Couldn't open wd";



	 foreach my $var ( @vars ){
		  chomp $var;
		  
		 #print ">>>" .  $var . "<<<\n";
		 my $cmd = "perl -i -wpe " . "\'s\/\\"$" . $var ."\"\/\$var::" . $var . "\"\/g\' wonderdesk.cgi"    ;
		 
		 print $cmd . "\n";
		 #print " count = $ct \n";
		 #$ct++;
 	#system ("$cmd") 	;#or die "Couldn't subst $var in $file" ;
	# #print or die " Couldn't print $file";
 	}

 





print "fini \n";
1;