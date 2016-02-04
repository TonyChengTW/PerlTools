#! /usr/local/bin/perl
#---------------------------------------
#Writer : Mico Cheng
#Version: 2005042901
#Host   : db01.aptg.net
#use for: suspend batch users
#---------------------------------------

use DBI;
$| = 1;
$suspend_file = shift;

die "./suspend_batch.pl <suspend list>\n" if (scalar(@ARGV)!=0);

$dsn=sprintf("DBI:mysql:%s;host=%s", 'mail_db', '210.200.211.3');
$dbh=DBI->connect($dsn, 'rmail', 'xxxxxxx') || die_db($!);

$dsn=sprintf("DBI:mysql:%s;host=%s", 'mail_db', '210.200.211.4');
$dbh_log=DBI->connect($dsn, 'rmail', 'xxxxxxx') || die_db($!);
#-------------------------------------------------------------------------
## Get suspend user data

$_ = `wc -l $suspend_file`;
($cnt) = $_ =~ /^\s+(\d+)\s+.*$/;

open SUSPEND_LST,("$suspend_file") or die "can't open :$suspend_file:$!\n";
while (<SUSPEND_LST>) {
    chomp;
    $s_mailid = $_;

    ###################   Mail Check  ############################
    $sqlstmt=sprintf("select s_mhost,s_mbox from MailCheck 
                      where s_mailid='%s'",$s_mailid);
    $sth2=$dbh->prepare($sqlstmt);
    $sth2->execute();
    ($s_mhost, $s_mbox)=$sth2->fetchrow_array;
    undef($sth2);
    ###################   Mail Pass  ############################
    $sqlstmt=sprintf("select s_encpass, s_rawpass, s_modifytime from MailPass
                      where s_mailid='%s'", $s_mailid);
    $sth2=$dbh->prepare($sqlstmt);
    $sth2->execute();
    ($s_encpass, $s_rawpass, $s_modifytime)=$sth2->fetchrow_array;
    undef($sth2);

    ################## Delete old data ############################
    $sqlstmt=sprintf("delete from MailCheck where s_mailid='%s'", $s_mailid);
    $dbh->do($sqlstmt);
    $sqlstmt=sprintf("delete from MailPass where s_mailid='%s'", $s_mailid);
    $dbh->do($sqlstmt);
    $sqlstmt=sprintf("delete from MailRecord_%s where s_mailid='%s'", 
                      substr($s_mailid, 0, 1), $s_mailid);
    $dbh_log->do($sqlstmt);

## Backup to suspend
    $sqlstmt=sprintf("insert into Suspend 
				 values('%s', '1', '%s', '%s', '%s', '%s', NOW())",
         $s_mailid, $s_rawpass, $s_mhost, $s_mbox, $s_modifytime);
    $dbh->do($sqlstmt);

		print "Process: $cnt  $s_mailid suspend done!\n";
		$cnt--;
}

$dbh->disconnect();
$dbh_log->disconnect();
