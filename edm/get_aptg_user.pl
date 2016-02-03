#! /usr/local/bin/perl
#  ----------------------------------
#   Writer : Nekobe
#   Modify by Mico Cheng 20041021
#   Use for : get aptg user
#   Host : aptg.net
#  ----------------------------------

use DBI;

require "/export/home/rmail/bin/config.pl";

$|++;
die "\n\n./get_aptg_user.pl \n\n" if (scalar(@ARGV)!=0);

$cnt=0;

open OUT, ">./all_aptg_user.list" or die "can't create:$!\n";

$dsn=sprintf("DBI:mysql:%s;host=%s", $DB{'mta'}{'name'}, $DB{'mta'}{'host'});
$dbh=DBI->connect($dsn, $DB{'mta'}{'user'}, $DB{'mta'}{'pass'})
        || die_db($!);

$sqlstmt=sprintf("select s_mailid from MailCheck");
$sth=$dbh->prepare($sqlstmt);
$sth->execute();

while (@row_array=$sth->fetchrow_array) {
  ($username) = (@row_array);
  print OUT "$username\n";
}
close(OUT);
