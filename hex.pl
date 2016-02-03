#!/usr/bin/perl
use Socket qw(:DEFAULT :crlf);
$a = hex('a');
print "a ==> hex $a\n";
$\ = CRLF;
$b = hex('{$\}');
print "$b";
