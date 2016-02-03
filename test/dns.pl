#!/usr/local/bin/perl
use Socket;

$name = $ARGV[0];  
@addresses = gethostbyname($name) or die "can't resolve $name: $!\n";
foreach (@addresses[4 .. $#addresses]) {
    @addr = inet_ntoa($_);
    print "$addr[1]\n";
}
