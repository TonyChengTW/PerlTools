#!/usr/bin/perl
use Net::DNS;
$res = Net::DNS::Resolver->new;
$| = 1;

$file_name = $ARGV[0];
open (FH, "$file_name") or die "can\'t open $file_name!\n";
while (<FH>) {
    chomp;
    $domain = $_;
    @mx = mx($res, $domain);
    if (! @mx) {
         print "$domain has MX RR\n";
         foreach $rr (@mx) {
      }
  } else {
      warn "Can't find MX records for $domain ", $res->errorstring, "\n";
      $query = $res->search($domain);
      if (! $query) {
         print "$domain No A & MX RRs\n";
      }
  }
}
