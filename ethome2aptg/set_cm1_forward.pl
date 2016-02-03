#!/usr/local/bin/perl
#  ----------------------------------
#   Writer  : Mico Cheng
#   Version : 2005042201
#   Use for : sete .forward file for cm1 to forward to aptg
#   Host : cm1
#  ----------------------------------
use DBI;
#----------------------------------------------------------------
until ($#ARGV == 0) {
     print "\nUsage:  set_cm1_forward.pl <forward file>\n";
print "forward file example:\n";
print "====================================\n";
print "miko@cm1.ethome.net.tw!miko@aptg.net\n";
exit 1;
}
## ---------------- Variables -----------------------
$forward_file = $ARGV[0];
$base_maildir = "/users_new";
$_ = `wc -l $forward_file`;
($cnt) = $_ =~ /^\s+(\d+)\s+.*$/;
$| = 1;

##======================================================================
open FORWARDLIST, "$forward_file" or die "can't open $forward_file:$!\n";

while (<FORWARDLIST>) {
    chomp;
		($old_mail,$new_mail) = $_ =~ /^(.*)\|(.*)$/;
    $_ = $old_mail;
    ($old_account) = $_ =~ /^(.*)\@cm1.ethome.net.tw$/;
    $ab_userdir = sprintf("/%s/%s/%s", $base_maildir, substr($old_account, 0, 1), $old_account);
		print "mkdir -p $ab_userdir\n";
		print "echo \'$new_mail\'> $ab_userdir/.forward\n";
}
