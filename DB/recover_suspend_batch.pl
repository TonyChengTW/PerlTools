#! /usr/local/bin/perl
#---------------------------------------
#Writer : Mico Cheng
#Version: 2005042901
#Host   : db01.aptg.net
#use for: recover suspend batch users
#---------------------------------------

use DBI;
$| = 1;
$recover_suspend_file = shift;

die "./recover_suspend_batch.pl <suspend list>\n" if (scalar(@ARGV)!=0);

$dsn=sprintf("DBI:mysql:%s;host=%s", 'mail_db', '210.200.211.3');
$dbh=DBI->connect($dsn, 'rmail', 'LykCR3t1') || die_db($!);
#-------------------------------------------------------------------------
## Get recover suspend user data

$_ = `wc -l $recover_suspend_file`;
($cnt) = $_ =~ /^\s+(\d+)\s+.*$/;
open RE_SUSPEND_LST,("$recover_suspend_file") 
        or die "can't open :$recover_suspend_file:$!\n";

while (<RE_SUSPEND_LST>) {
    chomp;
    $s_mailid = $_;

    ###################   Check MailCheck  ############################
    $sqlstmt=sprintf("select s_mhost,s_mbox from MailCheck 
                      where s_mailid='%s'",$s_mailid);
    $sth2=$dbh->prepare($sqlstmt);
    $sth2->execute();
		if ($sth2->rows!=0) {
			  print "the user: $s_mailid still active in MailCheck!\n";
				exit 0;
		}
    undef($sth2);
    ###################   Check MailPass  ############################
    $sqlstmt=sprintf("select s_encpass, s_rawpass, s_modifytime from MailPass
                      where s_mailid='%s'", $s_mailid);
    $sth2=$dbh->prepare($sqlstmt);
    $sth2->execute();
		if ($sth2->rows!=0) {
			  print "the user: $s_mailid still active in MailCheck!\n";
				exit 0;
		}
    undef($sth2);

    ################# Get Suspend Data ############################3
		$sqlstmt=sprintf("select s_rawpass, s_mhost, s_mbox from Suspend
				              where s_mailid='%s'", $s_mailid);
		$sth2=$dbh->prepare($sqlstmt);
		$sth2->execute();
		($s_rawpass, $s_mhost, $s_mbox)=$sth2->fetchrow_array;

		
    ################## Insert Suspend data to MailCheck ##################
    $sqlstmt=sprintf("insert into MailCheck values('%s','1','%s','%s','0')",                      $s_mailid, $s_mhost, $s_mbox);
    $dbh->do($sqlstmt);

    $sqlstmt=sprintf("insert into MailPass values('%s','1',ENCRYPT('%s'),'%s', NOW())", $s_mailid, $s_rawpass, $s_rawpass);
    $dbh->do($sqlstmt);

    $sqlstmt=sprintf("delete from Suspend where s_mailid='%s'", $s_mailid);
    $dbh->do($sqlstmt);

		print "Process: $cnt  $s_mailid recover suspend done!\n";
		$cnt--;
}

#$dbh->disconnect();
