#!/usr/bin/perl
use Socket;
use Net::DNS;
$res = Net::DNS::Resolver->new;
$| = 1;

$file_name = $ARGV[0];
open (FH, "$file_name") or die "can\'t open $file_name!\n";
while (<FH>) {
    chomp;
    $domain = $_;
    $query = $res->query("$domain", "NS");
    if ($query) {
        print "Domain : $domain : \n\n";
        foreach $rr (grep { $_->type eq 'NS' } $query->answer) {
              $nsdname = $rr->nsdname; 
              print "$nsdname  :  ";
              @addresses = gethostbyname($nsdname);
              @addresses = map { inet_ntoa($_) } @addresses[4 .. $#addresses];
              foreach $_ (@addresses) {
                  print "$_   ";
              }
              print "\n";
        }
        print "==============================================\n";
    }
    else {
             warn "Failed  $domain: ", $res->errorstring, "\n";
    }
}
