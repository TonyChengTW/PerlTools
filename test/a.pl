#!/usr/local/bin/perl
open (AA,">aa.list") or die "can't open $!\n";
select (AA);
do {
     $cnt++;
     next if ($cnt==50);
     print "$cnt\n";
     print AA "$cnt\n";
} while ($cnt<10000);
close (AA);
