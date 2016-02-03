#!/usr/local/bin/perl
$remove_list = shift;
$access_list = 'access';
$access_list_new = 'access.new';

$| = 1;
$i = 176196;

open ACCESS,"$access_list" or die "$!\n";
open REMOVE,"$remove_list" or die "$!\n";
open NEW,">$access_list_new" or die "$!\n";

while (<REMOVE>) {
   chomp;
   push (@remove_list,$_);
}

while (<ACCESS>) {
    chomp;
    $access_line = $_;
    print "process : $i\n";
    $i--;
    $write = 1;
    foreach $remove_item (@remove_list) {
       if ($access_line =~ /$remove_item/) {
           if ($flag{$remove_item} == 1) {
                 $write = 0;
           }
           $flag{$remove_item} = 1;
           last;
    _  }
    }
    next if ($write == 0);
    print NEW "$access_line\n";
}
