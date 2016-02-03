#!/usr/local/bin/perl

open FH,"all.txt" or die "can't open filr:$!\n";
open F1,">mailfrom.txt";
open F2,">mailto.txt";

while (<FH>) {
	chomp $_;
#print "$_\n";
	($mailfrom,$mailto) = $_ =~ /from \((.*)\) to \((.*)\)/;
	print F1 "from=$mailfrom\n";
	print F2 "to=$mailto\n";
}
