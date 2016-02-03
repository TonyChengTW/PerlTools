#!/usr/local/bin/perl
#  ----------------------------------
#   Writer  : Mico Cheng
#   Version : 2005042201
#   Use for : get cm1 forward list from tercel
#   Host : tercel
#  ----------------------------------
use DBI;
## --------------- tercel.aptg --------------------------
$tercel_ip = '203.79.224.102';
$tercel_account = 'brucelai';
$tercel_pwd = 'ezmailat60';
$tercel_name = 'dialup';

## ---------------- Variables -----------------------
$forward_file = "cm1_forward.list"; 
$base_maildir = "/users_new";
$| = 1;
$cm1_domain = '%cm1.ethome.net.tw';

# Open tercel.aptg.net
open FORWARDLIST, ">$forward_file" or die "can't open $forward_file:$!\n";

$dbh_tercel=DBI->connect("DBI:mysql:$tercel_name;host=$tercel_ip", $tercel_account, $tercel_pwd) or die "$!\n";

$sqlstmt=sprintf("select old_mail,new_mail from mailchang_log where old_mail like '%s'", $cm1_domain);
$sth=$dbh_tercel->prepare($sqlstmt);
$sth->execute();
while (($old_mail,$new_mail) = ($sth->fetchrow_array)[0,1]) {
    print FORWARDLIST "$old_mail|$new_mail\n";
}
close(FORWARDLIST);
