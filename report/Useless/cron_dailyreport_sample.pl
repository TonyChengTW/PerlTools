#!/usr/bin/perl
#-----------------------
# Version : 2004071601
# Writer  : Mico Cheng
# Use for : Daily Report
# Host    : 210.200.211.17
# Filename: cron_dailyreport.pl
#-----------------------

$reporter='tony@strongniche.com.tw';

open(REP1, "/mico/report/aptg-usage-report.txt");
open(REP2, "/mico/report/pflogsumm-report.txt");
open(PROG, "|/usr/lib/sendmail -t");
print PROG "Date: ", `date`;
print PROG "From: Mico Cheng\n";
print PROG "To: ".$reporter."\n";
print PROG "Subject: aptg.net Rmail Daily report\n";
print PROG "Total  Active User:\t$active users\n";
print PROG "MS01 Active User:\t$ms01_active users\n";
print PROG "MS02 Active User:\t$ms02_active users\n";
print PROG "MS03 Active User:\t$ms03_active users\n";
print PROG "Suspend User:\t$suspend users\n";
print PROG "TrustIP:\t$trustip IPs\n";
print PROG "DenyIP:\t$denyip IPs\n";
print PROG "DenyMailfrom:\t$denymailfrom E-Mails\n\n";

print PROG "\n================  aptg.net Usage Report ===========================\n\n\n";

while(<REP1>) {
    print PROG $_;
}

print PROG "\n================ Postfix log Summary Report ===========================\n\n\n";

while(<REP2>) {
    print PROG $_;
}

close(PROG);
close(REP1);
close(REP2);
