#! /usr/local/bin/perl
#  ----------------------------------
#   Writer : Nekobe
#   Modify by Mico Cheng 20040908
#   Use for : Move users account by batch file
#   Host : aptg.net
#  ----------------------------------

use DBI;

require "config.pl";

$|++;
die "\n\n./move_user.pl <list file> ms0x \n\n" if (scalar(@ARGV)!=2);
die "File ".$ARGV[0]." seem like doesn't exist!" if (!-e $ARGV[0]);

$cnt=0;
$file = $ARGV[0];
$domain_id = 1;
$t_mhost= $ARGV[1];
$dsn=sprintf("DBI:mysql:%s;host=%s", $DB{'mta'}{'name'}, $DB{'mta'}{'host'});
$dbh=DBI->connect($dsn, $DB{'mta'}{'user'}, $DB{'mta'}{'pass'})
        || die_db($!);
## Check if domain id is correct
$sqlstmt=sprintf("select s_basedir from DomainTransport where s_idx=%d", $domain_id);
$sth=$dbh->prepare($sqlstmt);
$sth->execute();
if ($sth->rows!=1) {
        $dbh->disconnect();
        die "Domain id $domain_id doesn't exist!\n";
}
($s_basedir)=($sth->fetchrow_array)[0];

## Read from file and build account
open(FH, "$file");
while (<FH>) {
        chomp();
        $s_mailid = $_;
        $s_mailid=lc($s_mailid);

        $s_mbox=sprintf("%s/%s/%s", substr($s_mailid, 0, 1), substr($s_mailid, 1, 1), $s_mailid);
        $s_deep1=sprintf("%s/%s/%s", $s_basedir, $t_mhost, substr($s_mailid, 0, 1));
        $s_deep3=sprintf("%s/%s/%s/%s/%s", $s_basedir, $t_mhost, substr($s_mailid, 0, 1), substr($s_mailid, 1, 1), $s_mailid);

        ## Query Moving Users' original s_mhost
        $sqlstmt=sprintf("select s_mhost from MailCheck where s_mailid='$s_mailid'");
        $sth=$dbh->prepare($sqlstmt);
        $sth->execute();
        if ($sth->rows !=1) {
             warn "This User:$s_mailid doesn't exist!\n";
             next;
        }
        ($s_mhost) = ($sth->fetchrow_array)[0];

        ## Update MailCheck Tables
        $sqlstmt=sprintf("update MailCheck set s_mhost='$t_mhost' where s_mailid='$s_mailid'");
        $dbh->do($sqlstmt);

        ## Create mdir
  $t_path=sprintf("%s/%s/%s", $s_basedir, $t_mhost, $s_mbox);
  $t_mhost_path=sprintf("%s/%s", $s_basedir, $t_mhost);

  $s_path=sprintf("/%s/%s/%s", $s_basedir, $s_mhost, $s_mbox);
        $t_maildir=sprintf("%s/Maildir/new/", $t_path);
        $s_maildir=sprintf("%s/Maildir/new/", $s_path);
        system("mkdir -p $t_maildir");
				print "Info: progress=$cnt\t$s_mailid is Copy files.wait....";
        system("cp $s_path/.quota-tmp $t_path 2>/dev/null");
        system("cp $s_maildir/* $t_maildir 2>/dev/null");
        system("/usr/local/bin/chown -R rmail:rmail $s_deep3");
        system("rm -rf $s_path");
        $cnt++;
        print "done!\n";
}
print "\n\n";
close(FH);
#$dbh->disconnect();
