#!/usr/local/bin/perl
open (FH,"mhost") or die "can't open mhost:$!\n";
while (<FH>) {
	chomp;
	if (-e $_ and -r $_ and -w $_ and -x $_) {
		    print "$_ is ok!\n";
	} else {
		    print "$_ is not ok!\n";
	}
}
