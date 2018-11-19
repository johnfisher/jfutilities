#!/usr/bin/perl -w
# a script that puts the correct text into every Root file
# in a tree, presumably CVS tree.
# check first to make sure there are no toher Root files

use File::Find;
use Cwd;

my $dir = getcwd();
my @lines =    ":pserver:jfisher\@pt:/usr/local/cvs\n";
find(\&edits, $dir);

sub edits() {

        $file = $_;
	if ( $file eq "Root") {
        open FILE, ">$file";
        
	print FILE @lines;
        close FILE;


	}

}
