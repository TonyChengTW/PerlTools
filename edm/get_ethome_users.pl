#! /usr/local/bin/perl
#  ----------------------------------
#   Writer : Mico Cheng
#   Version: 20040908
#   Use for : get ethome users (ms04.aptg.net)
#   Host : db01.aptg.net
#  ----------------------------------

use DBI;

$file = 'ethome_user.list';
open FH , ">$file" or die "can't open $file\n";

$dbh = DBI->connect("DBI:mysql:mail_db;host=210.200.211.3","rmail","xxxxxxx") || die_db($!);
## get ms04 users

$sqlstmt=sprintf("select s_mailid from MailCheck where s_mhost='%s'",'ms04');

$sth=$dbh->prepare($sqlstmt);
$sth->execute();
($result) = $sth->rows;
print "$result\n";
#if ($sth->rows!=1) {
#$dbh->disconnect();
#        die "no ms04 users\n";
#}

while (($user_account) = ($sth->fetchrow_array)[0]) {
	   print FH "$user_account\n";
}
close(FH);
