#!/usr/bin/perl
#------------------------
# Writer:  Mico Cheng
# Version: 2004080301
# Use for: find affected account in Mondeo Mailing list(¥¿¦Vªí¦C)
# Host:    --
#-----------------------
# 
$primary_list = "./mondeo.list";

$compared_list = "./alluser.20060117";

$output_list = "./affected.list";

open (PRIMARY, "$primary_list") or die "can\'t open $primary_list:$!\n";
open (COMPARED, "$compared_list") or die "can\'t open $compared_list:$!\n";
open (OUTPUT, ">$output_list") or die "can\'t open $oes_unlist:$!\n";

while(<PRIMARY>) {
    chomp;
    $primary_count++;
    push(@primary_arr, $_);
}

while(<COMPARED>) {
    chomp;
    $compared_count++;
    push(@compared_arr, $_);
}

@primary_arr = sort(@primary_arr);
@compared_arr = sort(@compared_arr);

&binary_search;

close PRIMARY;
close COMPARED;
close OUTPUT;

#-------------------------------------------
sub binary_search
{
    my($i,$high,$middle,$low);
    $i = 0;
    while ($i <= $primary_count-1) {
         $match = 0;
         $high = $compared_count-1;
         $low = 0;
         until ($low > $high) {
              $middle = int(($low+$high)/2);
              if ($primary_arr[$i] eq $compared_arr[$middle]) {
                     $match = 1;
										 print "$primary_arr[$i]\n";
                     last;
              } elsif ($primary_arr[$i] lt $compared_arr[$middle]) {
                     $high = $middle-1;
                     next;
              } else {
                     $low = $middle+1;
                     next;
              }
         }
         $i++;
    }
}
