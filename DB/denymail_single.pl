#!/usr/bin/perl
# ======================================================
# Writer   : Mico Cheng
# Version  : 20050104
# Use for  : add to DenyMailfrom
# Host     : 210.200.211.3
# ======================================================
if ($#ARGV != 1)
{
	     print "\nusage:    denymail <reason> <E-Mail> \n";
			      exit;
}


use DBI;
use Socket;

$dbh = DBI ->connect("DBI:mysql:mail_db;host=210.200.211.3", "rmail", "LykCR3t1") or die "$!\n";

$reason = $ARGV[0];
$denymail = $ARGV[1];

$sqlstmt = sprintf("select * from DenyMailfrom where s_mailfrom='%s'",$denymail);
$sth=$dbh->prepare($sqlstmt);
$sth->execute();
if ($sth->rows!=1) {
	    $sqlstmt = sprintf("\ninsert into DenyMailfrom values ('%s', NOW(), '%s')", $denymail, $reason);
			    print "$sqlstmt \n";
					    $dbh->do($sqlstmt);
} else {
	    ($s_mailfrom, $s_time, $s_reason)=($sth->fetchrow_array)[0,1,2];
			    print "\n This E-Mail have been already insert earler!\n";
					    print "$s_mailfrom | $s_time | $s_reason\n";
}
