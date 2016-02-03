#!/usr/bin/perl
use IO::Socket qw(:DEFAULT :crlf);
$host = shift || 'localhost';
$port = shift || '25';

$socket = IO::Socket::INET->new("$host:$port") or die "$@\n";
$child = fork();
die "can't fork:$!\n" unless defined($child);

if ($child) {
    $SIG{CHLD} = sub {exit 0};
    &server2client($socket);
    $socket->shutdown(1);
    sleep;
} else {
    &client2server($socket);
    print STDOUT "Client is out!\n";
}

sub server2client {
    $s = shift;
    $/ = CRLF;
    while(<$s>) {
        chomp;
        print STDOUT "$_\n";
    }
}

sub client2server{
    $s = shift;
    while(<>) {
        chomp;
        print $s $_,CRLF;
    }
}
