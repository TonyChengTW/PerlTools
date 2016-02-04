#!/usr/local/bin/perl
#  ----------------------------------
#   Writer  : Mico Cheng
#   Version : 2005032801
#   Use for : mail EDMs by system.
#   Host : pop3 server
#  ----------------------------------
use DBI;
#----------------------------------------------------------------
until ($#ARGV == 1) {
     print "\nUsage:  edm.pl  <account list>  <EDM file>\n";
print "account list:  file name with accounts\n";
print "EDM files   :  EDM pattern file\n";
exit 1;
}

## --------------- db01.aptg --------------------------
$db01_ip = '210.200.211.3';
$db01_account = 'rmail';
$db01_pwd = 'xxxxxxx';
$db01_name = 'mail_db';

## ---------------- Variables -----------------------
$account_file = $ARGV[0];
$edm_file = $ARGV[1];
$base_maildir = "/mnt";
$_ = `wc -l $account_file`;
($cnt) = $_ =~ /^\s+(\d+)\s+.*$/;
$| = 1;

# Open db01.aptg.net
$dbh_db01=DBI->connect("DBI:mysql:$db01_name;host=$db01_ip", $db01_account,
		                        $db01_pwd) or die "$!\n";

open ACCESSLIST, "$account_file" or die "can't open $account_list:$!\n";

while (<ACCESSLIST>) {
    chomp;
		($s_mailid) = $_ =~ /^(.*)$/;

		$sqlstmt=sprintf("SELECT s_mhost FROM MailCheck
				                  WHERE s_mailid='%s'", $s_mailid);
		$sth=$dbh_db01->prepare($sqlstmt);
		$sth->execute();
		($mhost) = ($sth->fetchrow_array)[0];

		&post2mdir($s_mailid, $mhost, $edm_file);
}

sub post2mdir {
    ($s_mailid, $mhost, $edm_file) = @_;

    $aptg_maildir = sprintf("/%s/%s/%s/%s/%s/Maildir/new/",$base_maildir,
        $mhost, substr($s_mailid, 0, 1), substr($s_mailid, 1, 1), $s_mailid);

    $mdir_file = sprintf("%s/%d.%05d1.00000000.00.00.%s",
        $aptg_maildir, time(), rand(10000), $mhost);

		system "cp $edm_file $mdir_file";
    system "/usr/local/bin/chown rmail:rmail $mdir_file";
    print "Info: $cnt ==> $s_mailid sent EDM!\n";
		$cnt--;
}
