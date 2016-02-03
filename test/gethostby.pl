#!/usr/local/bin/perl
use strict;
use Socket;

my $unpacked_addr = shift || '210.200.211.10';
my $family = '2';
my $packed_addr = inet_aton($unpacked_addr);
(my $name,my $aliases,my $type,my $len,my $packed_addr)=gethostbyaddr($packed_addr,$family);
#my $name = gethostbyaddr($packed_addr,$family);
print "name = $name\n";
print "aliases = $aliases\n";
print "type = $type\n";
print "len = $len\n";
print "unpacked_addr= $unpacked_addr\n";
