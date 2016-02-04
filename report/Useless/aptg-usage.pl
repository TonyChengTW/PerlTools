#!/usr/bin/perl
#------------------------
# Writer:  Mico Cheng
# Version: 2004071501
# Use for: Counting account who use ebtnet.net or aptg.net
# Host:    ms?
#-----------------------
use DBI;
$dumpfile = "/mico/report/valid.account";
$dbh = DBI->connect("DBI:mysql:mail_db;host=210.200.211.3", "rmail",'xxxxxxx') or die "$!\n";
$sqlstmt = sprintf("select s_mailid from MailCheck order by 1 asc");
$sth = $dbh->prepare($sqlstmt);
$sth->execute() or die "can not select:$!\n";

open (DUMPFILE, ">$dumpfile");
while(@row_array=$sth->fetchrow_array) {
     ($s_mailid) = (@row_array);
     print DUMPFILE "$s_mailid\n";
}
close DUMPFILE;

$sqlstmt = sprintf("select count(*) from MailCheck");
$sth = $dbh->prepare($sqlstmt);
$sth->execute() or die "can not select:$!\n";
$total_count = $sth->fetchrow_array;

#$dbh->disconnect();
#########   all #######
system "cat /backup/daily-report/ms.log|grep \'extract_addr: input:\'|awk \'{print \$11}\'|egrep -v \'ebtnet|aptg\'|sort|uniq > /mico/report/fuzzy-alldomain";

$_ = `cat /mico/report/fuzzy-alldomain|wc -l`;
($otherdomain_count) = /^\s+(\d+)/;
#########   ebtnet.net #######
system "cat /backup/daily-report/ms.log|grep \'extract_addr: input:.*\@ebtnet.net\'|awk \'{print \$11}\'|sort|uniq > /mico/report/fuzzy-ebtnet.account";

$_ = `cat /mico/report/fuzzy-ebtnet.account|wc -l`;
($ebtnet_count) = /^\s+(\d+)/;
##########  aptg.net #########
system "cat /backup/daily-report/ms.log|grep \'extract_addr: input:.*\@aptg.net\'|awk \'{print \$11}\'|sort|uniq > /mico/report/fuzzy-aptg.account";

$_ = `cat /mico/report/fuzzy-aptg.account|wc -l`;
($aptg_count) = /^\s+(\d+)/;
#########   Open & assign array to prepare compare acount ##########
open (VALID, "$dumpfile");
open (F_EBTNET, "/mico/report/fuzzy-ebtnet.account");
open (F_APTG, "/mico/report/fuzzy-aptg.account");
open (E_EBTNET, ">/mico/report/exact-ebtnet.account");
open (E_APTG, ">/mico/report/exact-aptg.account");

while(<VALID>) {
    chomp;
    next if ($_ eq '');
    push(@valid_account, $_);
}

while(<F_EBTNET>) {
    ($ebtnet_account) = /<(.+)@.*>/;
    push(@ebtnet_account, $ebtnet_account);
}

while(<F_APTG>) {
    ($aptg_account) = /<(.+)@.*>/;
    push(@aptg_account, $aptg_account);
}

&binary_search_ebt;
&binary_search_aptg;

close VALID;
close F_EBTNET;
close F_APTG;
close E_EBTNET;
close E_APTG;

#########   Counting Ratio #########
$our_user = $exact_ebtnet_account + $exact_aptg_account;
$aptg_ratio = $exact_aptg_account/$our_user;
$aptg_ratio*= 100;
$totaldomain_count = $otherdomain_count + $our_user;
print "ebtnet.net Unique Sender per day :$exact_ebtnet_account\n";
print "aptg.net    Unique Sender per day :$exact_aptg_account\n\n";
print "aptg & ebtnet Unique Sender per day\n(\@ebtnet.net + \@aptg.net):$our_user\n\n";
printf "Using \"xxx\@aptg.net\" ratio (aptg/(aptg+ebtnet)) : %.3f%\n\n", $aptg_ratio;
print "Other domain Unique Sender per day\n (all domain,but NOT include \@ebtnet.net + \@aptg.net):$otherdomain_count\n\n";
print "Total Unique Sender per day\n(all domain include \@ebtnet.net + \@aptg.net):$totaldomain_count\n\n";
########   End   ########################
#----------------------- Function ----------------------------------
sub binary_search_ebt
{
    my($i,$high,$middle,$low);
    $i = 0;
    while ($i <= $ebtnet_count-1) {
         $high = $total_count-1;
         $low = 0;
         until ($low > $high) {
              $middle = int(($low+$high)/2);
              if ($ebtnet_account[$i] eq $valid_account[$middle]) {
                     $exact_ebtnet_account++;
                     print E_EBTNET "$ebtnet_account[$i]\n";
                     last;
              } elsif ($ebtnet_account[$i] lt $valid_account[$middle]) {
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
#-------------------------------------------------------------------
sub binary_search_aptg
{
    my($i,$high,$middle,$low);
    $i = 0;
    while ($i <= $aptg_count-1) {
         $high = $total_count-1;
         $low = 0;
         until ($low > $high) {
              $middle = int(($low+$high)/2);
              if ($aptg_account[$i] eq $valid_account[$middle]) {
                     $exact_aptg_account++;
                     print E_APTG "$aptg_account[$i]\n";
                     last;
              } elsif ($aptg_account[$i] lt $valid_account[$middle]) {
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
