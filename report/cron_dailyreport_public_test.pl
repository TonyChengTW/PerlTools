#!/usr/bin/perl
#-----------------------
# Version : 2005012501
# Writer  : Mico Cheng
# Use for : Daily Report
# Host    : 210.200.211.17
# Filename: cron_dailyreport_public.pl
#-----------------------

use DBI;
use Net::SMTP;

require "/export/home/rmail/bin/config.pl";

$smtp_server = '210.200.136.1';
$sender = 'mikocheng@aptg.com.tw';
#@recipients = qw( idc@apol.com.tw mikocheng@aptg.com.tw );
@recipients = qw( mikocheng@apol.com.tw );
foreach (@recipients) { $recipients=$recipients."  ".$_ };

$TODAY = `date +%Y%m%d`;
$YESTERDAY = $TODAY-1;

$topn = 50;

# Generate Report
##-------------------- Amavis report --------  For MX/SMTP Server -----
print "Generating MX logs : amavis\n";
#system "/mico/report/amavis-report.pl '/backup/maillog/mx*$YESTERDAY*' > /mico/report/mx_amavis.micologsumm";
print "Generating SMTP logs : amavis\n";
#system "/mico/report/amavis-report.pl '/backup/maillog/smtp*$YESTERDAY*' > /mico/report/smtp_amavis.micologsumm";

#-------------------- MX logs report -----------------------------
print "Generating MX logs : mailfrom\n";
#system "/mico/mail_statistics/smtpd/smtpd_statistics.pl mailfrom $topn '/backup/maildebug/mx*$YESTERDAY*' > /mico/report/mx_mailfrom.micologsumm";

print "Generating MX logs : ip\n";
#system "/mico/mail_statistics/smtpd/smtpd_statistics.pl ip $topn '/backup/maildebug/mx*$YESTERDAY*' > /mico/report/mx_ip.micologsumm";

print "Generating MX logs : spammail\n";
#system "/mico/mail_statistics/smtpd/smtpd_statistics.pl spammail $topn '/backup/maillog/mx*$YESTERDAY*' > /mico/report/mx_spammail.micologsumm";

print "Generating MX logs : error\n";
#system "/mico/mail_statistics/smtpd/smtpd_statistics.pl error $topn '/backup/maillog/mx*$YESTERDAY*' > /mico/report/mx_error.micologsumm";

#-------------------- SMTP logs report -----------------------------
print "Generating SMTP logs : mailfrom\n";
#system "/mico/mail_statistics/smtpd/smtpd_statistics.pl mailfrom $topn '/backup/maildebug/smtp*$YESTERDAY*' > /mico/report/smtp_mailfrom.micologsumm";

print "Generating SMTP logs : ip\n";
#system "/mico/mail_statistics/smtpd/smtpd_statistics.pl ip $topn '/backup/maildebug/smtp*$YESTERDAY*' > /mico/report/smtp_ip.micologsumm";

print "Generating SMTP logs : spammail\n";
#system "/mico/mail_statistics/smtpd/smtpd_statistics.pl spammail $topn '/backup/maillog/smtp*$YESTERDAY*' > /mico/report/smtp_spammail.micologsumm";

print "Generating SMTP logs : error\n";
#system "/mico/mail_statistics/smtpd/smtpd_statistics.pl error $topn '/backup/maillog/smtp*$YESTERDAY*' > /mico/report/smtp_error.micologsumm";

#-------------------- MS logs report ------------------------------
print "Generating MS logs : mailfrom\n";
#system "/mico/mail_statistics/smtpd/smtpd_statistics.pl mailfrom $topn '/backup/maildebug/ms*$YESTERDAY*' > /mico/report/ms_mailfrom.micologsumm";

print "Generating MS logs : ip\n";
#system "/mico/mail_statistics/smtpd/smtpd_statistics.pl ip $topn '/backup/maildebug/ms*$YESTERDAY*' > /mico/report/ms_ip.micologsumm";

print "Generating MS logs : error\n";
#system "/mico/mail_statistics/smtpd/smtpd_statistics.pl error $topn '/backup/maildebug/ms*$YESTERDAY*' > /mico/report/ms_error.micologsumm";

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
$sqlstmt=sprintf("select count(*) from AllowIP");
$sth=$dbh->prepare($sqlstmt);
$sth->execute();

($allowip) = ($sth->fetchrow_array)[0];

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

print "Sending E-Mail to $recipients.....please wait...\n";

open(REP1,  "/mico/report/mx_amavis.micologsumm");
open(REP2,  "/mico/report/smtp_amavis.micologsumm");
open(REP3,  "/mico/report/mx_mailfrom.micologsumm");
open(REP4,  "/mico/report/mx_ip.micologsumm");
open(REP5,  "/mico/report/mx_spammail.micologsumm");
open(REP6,  "/mico/report/mx_error.micologsumm");
open(REP7,  "/mico/report/smtp_mailfrom.micologsumm");
open(REP8,  "/mico/report/smtp_ip.micologsumm");
open(REP9,  "/mico/report/smtp_spammail.micologsumm");
open(REP10,  "/mico/report/smtp_error.micologsumm");
open(REP11,  "/mico/report/ms_mailfrom.micologsumm");
open(REP12, "/mico/report/ms_ip.micologsumm");
#open(REP13, "/mico/report/ms_error.micologsumm");

open(CONTENT, ">content.txt");
print CONTENT "Date: ", `date`;
print CONTENT "From: ".$sender."\n";
print CONTENT "To: ".$recipients."\n";
print CONTENT "Subject: aptg.net Rmail Daily report-$YESTERDAY\n";
#print CONTENT "Subject: test, test , test,aptg.net Rmail Daily report\n";
print CONTENT "\n================ aptg.net User Report ================================================\n";
print CONTENT "Query Date:\t$YESTERDAY\n";
print CONTENT "Total  Active User:\t$active users\n";
print CONTENT "MS01 Active User:\t$ms01_active users\n";
print CONTENT "MS02 Active User:\t$ms02_active users\n";
print CONTENT "MS03 Active User:\t$ms03_active users\n";
print CONTENT "MS04 Active User:\t$ms04_active users\n";
print CONTENT "Suspend User:\t$suspend users\n";
print CONTENT "Trust IP(Relay IP):\t$trustip IPs\n";
print CONTENT "Allow IP(Whitelist):\t$allowip IPs\n";
print CONTENT "Deny IP(Blacklist):\t$denyip IPs\n";
print CONTENT "Deny Mailfrom(Blacklist):\t$denymailfrom E-Mails\n\n";

print CONTENT "\n\n\n================ MX Server Amavis Report ================================================\n"; while(<REP1>) { print CONTENT $_; }

print CONTENT "\n\n\n================ SMTP Server Amavis Report ==============================================\n"; while(<REP2>) { print CONTENT $_; }

print CONTENT "\n\n\n================ MX Server Mailfrom top$topn Report =====================================\n"; while(<REP3>) { print CONTENT $_; }

print CONTENT "\n\n\n================ MX Server Source IP top$topn Report ====================================\n"; while(<REP4>) { print CONTENT $_; }

print CONTENT "\n\n\n================ MX Server Spam Mailfrom top$topn Report ================================\n"; while(<REP5>) { print CONTENT $_; }

print CONTENT "\n\n\n================ MX Server Error top$topn Report ================================\n"; while(<REP6>) { print CONTENT $_; }

print CONTENT "\n\n\n================ SMTP Server Mailfrom top$topn Report ===================================\n"; while(<REP7>) { print CONTENT $_; }

print CONTENT "\n\n\n================ SMTP Server Source IP top$topn Report ==================================\n"; while(<REP8>) { print CONTENT $_; }

print CONTENT "\n\n\n================ SMTP Server Spam Mailfrom top$topn Report ==============================\n"; while(<REP9>) { print CONTENT $_; }

print CONTENT "\n\n\n================ SMTP Server Error top$topn Report ==============================\n"; while(<REP10>) { print CONTENT $_; }

print CONTENT "\n\n\n================ MS Server Mailfrom top$topn Report =====================================\n"; while(<REP11>) { print CONTENT $_; }

print CONTENT "\n\n\n================ MS Server Source IP top$topn Report ====================================\n"; while(<REP12>) { print CONTENT $_; }

print CONTENT "\n\n\n================ MS Server Error top$topn Report ====================================\n"; while(<REP13>) { print CONTENT $_; }

close(CONTENT);

# Use SMTP module to send out
$smtp = Net::SMTP->new($smtp_server,Timeout=>60);
$smtp->mail($sender);
$smtp->recipient(@recipients,{SkipBad=>1});
open CONTENT, "content.txt" or die "can not open content.txt";
$smtp->data;
while(<CONTENT>) {
	    $smtp->datasend($_);
}
$smtp->dataend;
$smtp->quit;

close(CONTENT);
