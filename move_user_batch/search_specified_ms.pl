#! /usr/local/bin/perl
#  ----------------------------------
#   Writer : Nekobe
#   Modify by Mico Cheng 20041021
#   Use for : search specified ms
#   Host : aptg.net
#  ----------------------------------

use DBI;

require "config.pl";

$|++;
die "\n\n./search_specified_ms.pl <list file> ms0x <out file> \n\n" if (scalar(@ARGV)!=3);
die "File ".$ARGV[0]." seem like doesn't exist!" if (!-e $ARGV[0]);

$cnt=0;
$file = $ARGV[0];
$outfile = $ARGV[2];
$domain_id = 1;
$t_mhost= $ARGV[1];

open OUT, ">$outfile" or die "can't create $outfile:$!\n";

$dsn=sprintf("DBI:mysql:%s;host=%s", $DB{'mta'}{'name'}, $DB{'mta'}{'host'});
$dbh=DBI->connect($dsn, $DB{'mta'}{'user'}, $DB{'mta'}{'pass'})
        || die_db($!);
## Check if domain id is correct

## Read from file and build account
open(FH, "$file");
while (<FH>) {
        chomp();
        $s_mailid = $_;
        $s_mailid=lc($s_mailid);

        ## Query Moving Users' original s_mhost
        $sqlstmt=sprintf("select s_mhost from MailCheck where s_mailid='$s_mailid' AND s_mhost='$t_mhost'");
        $sth=$dbh->prepare($sqlstmt);
        $sth->execute();
        if ($sth->rows !=1) {
             next;
        }
				print OUT "$s_mailid\n";
}
print "\n";
close(FH);
close(OUT);
#$dbh->disconnect();
