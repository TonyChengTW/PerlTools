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

$smtp_server = '210.200.211.36';
$sender = 'mikocheng@aptg.com.tw';
#@recipients = qw( idc-apol@aptg.com.tw );
@recipients = qw( mikocheng@aptg.com.tw tony@strongniche.com.tw );
foreach (@recipients) { $recipients=$recipients."  ".$_ };

$TODAY = `date +%Y%m%d`;
$YESTERDAY = $TODAY-1;

$topn = 50;

# Generate Report
##-------------------- Mail Statistics --------  For MX/SMTP Server -----
print "Generating MX logs : statistics\n";
print "Generating SMTP logs : statistics\n";

#-------------------- MX logs report -----------------------------
print "Generating MX logs : mailfrom\n";

print "Generating MX logs : ip\n";

print "Generating MX logs : spammail\n";

print "Generating MX logs : error\n";

#-------------------- SMTP logs report -----------------------------
print "Generating SMTP logs : mailfrom\n";

print "Generating SMTP logs : ip\n";

print "Generating SMTP logs : spammail\n";

print "Generating SMTP logs : error\n";

#-------------------- MS logs report ------------------------------
print "Generating MS logs : mailfrom\n";

print "Generating MS logs : ip\n";

print "Generating MS logs : error\n";

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

open(REP1,  "/mico/report/mx_mico-statistics.log");
open(REP2,  "/mico/report/smtp_mico-statistics.log");
open(REP3,  "/mico/report/mx_mailfrom_mico-statistics.log");
open(REP4,  "/mico/report/mx_ip_mico-statistics.log");
open(REP5,  "/mico/report/mx_spammail_mico-statistics.log");
open(REP6,  "/mico/report/mx_error_mico-statistics.log");
open(REP7,  "/mico/report/smtp_mailfrom_mico-statistics.log");
open(REP8,  "/mico/report/smtp_ip_mico-statistics.log");
open(REP9,  "/mico/report/smtp_spammail_mico-statistics.log");
open(REP10,  "/mico/report/smtp_error_mico-statistics.log");
open(REP11,  "/mico/report/ms_mailfrom_mico-statistics.log");
open(REP12, "/mico/report/ms_ip_mico-statistics.log");
open(REP13, "/mico/report/ms_error_mico-statistics.log");

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

print CONTENT "\n\n\n================ MX Server Statistics ================================================\n"; while(<REP1>) { print CONTENT $_; }

print CONTENT "\n\n\n================ SMTP Server Statistics ==============================================\n"; while(<REP2>) { print CONTENT $_; }

print CONTENT "\n\n\n================ MX Server Mailfrom top$topn Statistics =====================================\n"; while(<REP3>) { print CONTENT $_; }

print CONTENT "\n\n\n================ MX Server Source IP top$topn Statistics ====================================\n"; while(<REP4>) { print CONTENT $_; }

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
