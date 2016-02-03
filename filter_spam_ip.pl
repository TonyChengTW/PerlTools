#!/usr/bin/perl
use Socket;
system "cat /var/spool/imap/user/tony/SPAM/*. > /var/spool/imap/user/tony/SPAM/tmp.txt";
open FH,"/var/spool/imap/user/tony/SPAM/tmp.txt" or die "Error:$!\n";
$| = 1;

while (<FH>) {
   chomp();
   ($ip) = $_ =~ /\[(\d+\.\d+\.\d+\.\d+)\]/;
   next until defined($ip);
   next if ($ip =~ /127.0.0.1|221.169.6.9|221.169.16.108/);
   push (@unsorted_ip,$ip);
   @ip = uniq(@unsorted_ip);
   @sorted_ip = sort(@ip);
}

foreach (@sorted_ip) {
   $packed_ip = inet_aton($_);
   $fqdn = gethostbyaddr($packed_ip,AF_INET);
   print "$_  ==>  $fqdn\n";
}

sub uniq {
    my %hash = map { ($_,0 ) } @_;
    return keys %hash;
}
