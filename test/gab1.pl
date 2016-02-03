#!/usr/local/bin/perl

use strict;
use IO::Socket qw(:DEFAULT :crlf);
#use IO::Socket;
my $host = shift or die "Usage: gab1.pl host [port]\n";
my $port = shift || 'echo';
my $socket = IO::Socket::INET->new(PeerAddr => $host,PeerPort => $port)
             or die "Can't connect : $!  :$@\n";

my ($from_server,$from_user);

while ($from_server = <$socket>) {
     print "\$/=scalar($/)\n";
     #local $/ = CRLF;
     chomp $from_server;
     print $from_server,"\n";

     last unless $from_user = <>;
         #chomp $from_user;$from_user =~ s/\r//;
         chomp $from_user;
         print $socket "$from_user";
}
