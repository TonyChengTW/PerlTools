#! /usr/local/bin/perl
#---------------------------------------
#Writer : Mico Cheng
#Version: 2006011701
#Host   : db01.aptg.net
#use for: get aptg.net users
#---------------------------------------

use DBI;
$| = 1;

die "./delete_user_mail.pl\n" if (scalar(@ARGV)!=0);

$dsn=sprintf("DBI:mysql:%s;host=%s", 'mail_db', '210.200.211.3');
$dbh=DBI->connect($dsn, 'rmail', 'LykCR3t1') || die_db($!);

##################   Check MailCheck  ############################
$sqlstmt=sprintf("select s_mhost,s_mbox from Suspend where s_mhost !='' OR s_mbox !=''");
$sth2=$dbh->prepare($sqlstmt);
$sth2->execute();
if ($sth2->rows==0) {
    print "Nothing found in Suspend!\n";
    $dbh->disconnect();
    exit 0;
} else {
    $sth2=$dbh->prepare($sqlstmt);
    $sth2->execute();
    while(@Suspend=$sth2->fetchrow_array) {
        $cnt++;
        ($s_mhost,$s_mbox) = (@Suspend);
        print "$cnt : rm -rf /mnt/$s_mhost/$s_mbox\n";
        system "rm -rf /mnt/$s_mhost/$s_mbox\n";
    }
    print "Total User: $cnt\n";
}
