#!/usr/bin/perl
#------------------------
# Writer:  Mico Cheng
# Version: 2004071501
# Use for: MX Server Mail Statistics
# Host:    mx?
#-----------------------
$mx_report = "/mico/report/mx_mail-report.txt";
open MX_REPORT, (">$mx_report") or die "Can\'t open $mx_report:$!\n";

$today=`date +%Y%m%d`;
$yesterday = $today - 1;
@logs = `gunzip -c /backup/maillog/mx*-maillog-$yesterday.gz |grep Hits:`;
foreach (@logs) {
    $total++;
    if ($_ =~ /INFECTED/) {
          $virus++;
          next;
    }
    ($score) = /Hits:\s(\d+\.?\d+)$/; 
    $spam++ if ($score >= 7.5);
}
print MX_REPORT "MX Server total mail : $total\n";
print MX_REPORT "-----\n";
print MX_REPORT "MX Server total spam : $spam\n";
print MX_REPORT "MX Server total virus: $virus\n\n\n";
printf MX_REPORT "Spam  Ratio : %.3f%\n" , $spam/$total*100;
printf MX_REPORT "Virus Ratio : %.3f%\n" , $virus/$total*100;

close MX_REPORT
