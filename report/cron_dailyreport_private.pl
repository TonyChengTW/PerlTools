#!/usr/bin/perl
#-----------------------
# Version : 20040819/1111
# Writer  : Mico Cheng
# Use for : Daily Report
# Host    : 210.200.211.17
# Filename: cron_dailyreport.pl
#-----------------------

use DBI;
require "/export/home/rmail/bin/config.pl";
$reporter='mikocheng@aptg.com.tw';

$TODAY = `date +%Y%m%d`;
$YESTERDAY = $TODAY-1;
system "gunzip -c /backup/maillog/ms0[1-4]*$YESTERDAY*.gz > /backup/daily-report/ms.log";
system "gunzip -c /backup/maillog/mx*$YESTERDAY*.gz > /backup/daily-report/mx.log";
system "gunzip -c /backup/maillog/smtp*$YESTERDAY*.gz > /backup/daily-report/smtp.log";
#--------------------  MX Server Mail Statistics (virus & spam)-----------
#system "/mico/report/mx_mail-report.pl";

#--------------------  aptg.net Usage -----------------------
#system "/mico/report/aptg-usage.pl > /mico/report/aptg-usage-report.txt";

#--------------------  pflogsumm -----------------------------
#system "/mico/report/pflogsumm -d yesterday -h 6 -u 5 --smtpd_stats /backup/daily-report/ms.log > /mico/report/pflogsumm-report-ms.txt";

system "/mico/report/pflogsumm -d yesterday --no_bounce_detail --no_no_msg_size -h 20 -u 20 --smtpd_stats /backup/daily-report/ms.log > /mico/report/pflogsumm-report-ms.txt";

system "/mico/report/pflogsumm -d yesterday --no_bounce_detail --no_no_msg_size -h 20 -u 20 --smtpd_stats /backup/daily-report/mx.log > /mico/report/pflogsumm-report-mx.txt";

system "/mico/report/pflogsumm -d yesterday --no_bounce_detail --no_no_msg_size -h 20 -u 20 --smtpd_stats /backup/daily-report/smtp.log > /mico/report/pflogsumm-report-smtp.txt";

#-------------------  Counting DB -------------------------------
$dsn=sprintf("DBI:mysql:%s;host=%s", $DB{'mta'}{'name'}, $DB{'mta'}{'host'});
$dbh=DBI->connect($dsn, $DB{'mta'}{'user'}, $DB{'mta'}{'pass'}) || die_db($!);
#------------------------------------------------------------
$sqlstmt=sprintf("select count(*) from MailCheck");
$sth=$dbh->prepare($sqlstmt);
$sth->execute();

($active) = ($sth->fetchrow_array)[0];
#============================================================
$sqlstmt=sprintf("select count(*) from MailCheck where s_mhost='ms01' or s_mhost='ms06' or s_mhost='ms11' or s_mhost='ms16' or s_mhost='ms21'");
$sth=$dbh->prepare($sqlstmt);
$sth->execute();
($ms01_active) = ($sth->fetchrow_array)[0];

#============================================================
$sqlstmt=sprintf("select count(*) from MailCheck where s_mhost='ms02' or s_mhost='ms07' or s_mhost='ms12' or s_mhost='ms17' or s_mhost='ms22'");
$sth=$dbh->prepare($sqlstmt);
$sth->execute();
($ms02_active) = ($sth->fetchrow_array)[0];

#============================================================
$sqlstmt=sprintf("select count(*) from MailCheck where s_mhost='ms03' or s_mhost='ms08' or s_mhost='ms13' or s_mhost='ms18' or s_mhost='ms23'");
$sth=$dbh->prepare($sqlstmt);
$sth->execute();
($ms03_active) = ($sth->fetchrow_array)[0];
#============================================================
$sqlstmt=sprintf("select count(*) from MailCheck where s_mhost='ms04' or s_mhost='ms09' or s_mhost='ms14' or s_mhost='ms19' or s_mhost='ms24'");
$sth=$dbh->prepare($sqlstmt);
$sth->execute();
($ms04_active) = ($sth->fetchrow_array)[0];
#============================================================
$sqlstmt=sprintf("select count(*) from Suspend");
$sth=$dbh->prepare($sqlstmt);
$sth->execute();

($suspend) = ($sth->fetchrow_array)[0];
#===========================================================
$sqlstmt=sprintf("select count(*) from TrustIP");
$sth=$dbh->prepare($sqlstmt);
$sth->execute();

($trustip) = ($sth->fetchrow_array)[0];

#===========================================================
$sqlstmt=sprintf("select count(*) from DenyIP");
$sth=$dbh->prepare($sqlstmt);
$sth->execute();

($denyip) = ($sth->fetchrow_array)[0];
#===========================================================
$sqlstmt=sprintf("select count(*) from DenyMailfrom");
$sth=$dbh->prepare($sqlstmt);
$sth->execute();

($denymailfrom) = ($sth->fetchrow_array)[0];
#============================================================
undef $sth;
$dbh->disconnect;

#open(REP1, "/mico/report/mx_mail-report.txt");
#open(REP2, "/mico/report/aptg-usage-report.txt");
open(REP3, "/mico/report/pflogsumm-report-mx.txt");
open(REP4, "/mico/report/pflogsumm-report-ms.txt");
open(REP5, "/mico/report/pflogsumm-report-smtp.txt");
open(PROG, "|/usr/lib/sendmail -t");
print PROG "Date: ", `date`;
print PROG "From: mikocheng\@aptg.com.tw\n";
print PROG "To: ".$reporter."\n";
print PROG "Subject: aptg.net Rmail Daily report (Pirvate)-$YESTERDAY\n";
print PROG "\n================ aptg.net User Report =============================\n\n\n";
print PROG "Total  Active User:\t$active users\n";
print PROG "MS01 Active User:\t$ms01_active users\n";
print PROG "MS02 Active User:\t$ms02_active users\n";
print PROG "MS03 Active User:\t$ms03_active users\n";
print PROG "MS04 Active User:\t$ms04_active users\n";
print PROG "Suspend User:\t$suspend users\n";
print PROG "TrustIP:\t$trustip IPs\n";
print PROG "DenyIP:\t$denyip IPs\n";
print PROG "DenyMailfrom:\t$denymailfrom E-Mails\n\n";

#print PROG "\n================ MX Server Spam & Virus Report ====================\n\n\n";

#while(<REP1>) {
#    print PROG $_;
#}

#print PROG "\n================  aptg.net Usage Report ===========================\n\n\n";

#while(<REP2>) {
#    print PROG $_;
#}

print PROG "\n================ MX Server Summary Report =========================\n\n\n";

while(<REP3>) {
    print PROG $_;
}

print PROG "\n================ MS Server Summary Report =========================\n\n\n";

while(<REP4>) {
    print PROG $_;
}

print PROG "\n================ SMTP Server Summary Report =========================\n\n\n";

while(<REP5>) {
    print PROG $_;
}

system "rm -rf /backup/daily-report/*";

close(PROG);
#close(REP1);
#close(REP2);
close(REP3);
close(REP4);
close(REP5);
