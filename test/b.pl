#!/usr/local/bin/perl
use strict;

my $interruptions = 0;
$SIG{INT} = $SIG{QUIT} = \&handle_interruptions;

while ($interruptions < 10) {
     print "I'm sleeping\n";
     #$SIG{INT} = "DEFAULT" if ($interruptions == 5);
     sleep(1);
}

sub handle_interruptions {
    my $sig = shift;
    $interruptions++;
    print "$sig You are the $interruptions time to break me\n";
}
