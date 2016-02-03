#! /usr/local/bin/perl
#---------------------------------------
#Writer : Mico Cheng
#Version: 2006011701
#Host   : db01.aptg.net
#use for: get aptg.net users
#---------------------------------------

use DBI;
$| = 1;

die "./get_users.pl\n" if (scalar(@ARGV)!=0);

$dsn=sprintf("DBI:mysql:%s;host=%s", 'mail_db', '210.200.211.3');
$dbh=DBI->connect($dsn, 'rmail', 'LykCR3t1') || die_db($!);

##################   Check MailCheck  ############################
$sqlstmt=sprintf("select s_mailid from MailCheck where 1=1");
$sth2=$dbh->prepare($sqlstmt);
$sth2->execute();
if ($sth2->rows==0) {
    print "Nothing found in MailCheck!\n";
    $dbh->disconnect();
    exit 0;
} else {
    $sth2=$dbh->prepare($sqlstmt);
    $sth2->execute();
    while(@MailCheck=$sth2->fetchrow_array) {
        ($s_mailid) = (@MailCheck);
        print "$s_mailid\n";
        $cnt++;
    }
    print "Total User: $cnt\n";
}
