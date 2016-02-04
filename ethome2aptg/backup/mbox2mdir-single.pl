#!/usr/local/bin/perl
#  ----------------------------------
#   Writer  : Mico Cheng
#   Version : 2004092901
#   Use for :
#   Host : x
#  ----------------------------------
use Net::FTP;
use DBI;

## ---------------- Variables -----------------------
$aptg_deep1_maildir = "/mnt";
$transfer_tmpdir = "/mico/ethome2aptg/tmp";
$old_mail = shift or die "Usage: mbox2mdir-single.pl <old E-mail>\n";

## --------------- db01.aptg --------------------------
$db01_ip = '210.200.211.3';
$db01_account = 'rmail';
$db01_pwd = 'xxxxxxx';
$db01_name = 'mail_db';

## -----------------    Tercel -----------------------
$tercel_ip = '203.79.224.102';
$tercel_account = 'brucelai';
$tercel_pwd = 'ezmailat60';
$tercel_name = 'dialup';

## -----------------  all ftp ethome -----------------------
$ethome_ip = '210.58.94.70';
$ethome_account = 'ftpuser';
$ethome_pwd = 'U83cjo$';
$ethome_deep1_maildir = '/';
$ethome_mbox_file = 'mbox';

$cm1_ip = '210.58.94.22';
$cm1_account = '';
$cm1_pwd = '';
$cm1_deep1_maildir = '/';
$cm1_mbox_file = 'mbox';

$hc_ip = '210.58.94.31';
$hc_account = '';
$hc_pwd = '';
$hc_maildir = '/';

#-------------------------------------------------------------
# Open Tercel
$dbh_tercel=DBI->connect("DBI:mysql:$tercel_name;host=$tercel_ip", $tercel_account,$tercel_pwd) or die "$!\n";


# Open db01.aptg.net
$dbh_db01=DBI->connect("DBI:mysql:$db01_name;host=$db01_ip", $db01_account,
                        $db01_pwd) or die "$!\n";

###----------------------------   Transfer mbox2mdir ------------------
# Getting transfer mail list
print "\nInfo: Transfer mbox2mdir ........\n\n";

($old_account,$old_host) = ($old_mail =~ /^(.*)@(.*?)\..*$/);
$old_account = lc($old_account); $old_host = lc($old_host);

$sqlstmt=sprintf("SELECT old_mail,new_mail FROM mailchang_log
                  WHERE old_mail like '%s\@%s%'",$old_account,$old_host);

$sth=$dbh_tercel->prepare($sqlstmt);
$sth->execute();
if ($sth->rows==0) {
   print "Warn: no such old user:$old_mail tranfered to aptg \n";
   exit;
}

while (($old_mail,$new_mail)=($sth->fetchrow_array)[0,1]) {
    ($new_account) = ($new_mail =~ /^(.*)@.*$/);
# Get aptg_maildir
    $sqlstmt = sprintf("SELECT s_mhost from MailCheck where s_mailid='%s'",
                        $new_account);
    $sth_db01 = $dbh_db01->prepare($sqlstmt);
    $sth_db01->execute();
    if ($sth_db01->rows==0) {
        print "Warn: no such user in aptg.net : $new_account \n";
        exit;
    } else {
        ($mhost) = ($sth_db01->fetchrow_array)[0];
        $aptg_maildir = sprintf("%s/%s/%s/%s/%s/Maildir/new/",$aptg_deep1_maildir, $mhost, substr($new_account, 0, 1), substr($new_account, 1, 1), $new_account);

        $aptg_deep2_maildir = sprintf("%s/%s/%s/%s/",$aptg_deep1_maildir, $mhost, substr($new_account, 0, 1), substr($new_account, 1, 1));

        !system("mkdir -p $aptg_maildir") or die "Warn: error mkdir $aptg_maildir\n";
    }


# Create FTP object
    chdir($transfer_tmpdir);
    if ($old_host eq 'ethome') {
        $ethome_maildir = sprintf("%s/%s/%s",$ethome_deep1_maildir,
                                   substr($old_account,0,1),$old_account);
        $ethome_ftp = Net::FTP->new($ethome_ip) 
                              or die "can't connect to $old_host:$@\n";
        $ethome_ftp->login($ethome_account,$ethome_pwd)
                              or warn "$ethome_ftp->message";
        $ethome_ftp->ascii or warn "$ethome_ftp->message";
        $ethome_ftp->cwd($ethome_maildir) or warn "Warn: $ethome_ftp->message";
        $ethome_ftp->get($ethome_mbox_file) or warn "Warn: $ethome_ftp->message :$!";
        $ethome_ftp->quit;
        if (-z $ethome_mbox_file) {
            print "Info: the old user: $old_account didn't need to convert mailbox\n";
            exit;
        }
        &mbox2mdir($ethome_mbox_file,$aptg_maildir,$mhost);
        system("/usr/local/bin/chown -R rmail:rmail $aptg_deep2_maildir");
        next;
    } elsif ($old_host eq 'cm1') {
        print "Info: this is cm1 account $old_account\@$old_host\n";
        exit;
    } elsif ($old_host eq 'hc') {
        $hc_mbox_file = $old_account;
        $hc_ftp = Net::FTP->new($hc_ip)
                              or die "can't connect to $old_host:$@\n";
        $hc_ftp->login($hc_account,$hc_pwd)
                              or warn "$hc_ftp->message";
        $hc_ftp->ascii or warn "$hc_ftp->message";
        $hc_ftp->cwd($hc_maildir) or warn "Warn: $hc_ftp->message";
        $hc_ftp->get($old_account) or warn "Warn: $hc_ftp->message";
        $hc_ftp->quit;
        &mbox2mdir($hc_mbox_file,$aptg_maildir,$mhost);
        system("/usr/local/bin/chown -R rmail:rmail $aptg_deep2_maildir");
        exit;
    } else {
        print "Warn: unknown host --> $old_account\@$old_host\n";
        exit;
    }
}

sub mbox2mdir {
    ($mbox_file, $aptg_maildir, $mhost) = @_;
    open MBOX, "$transfer_tmpdir/$mbox_file" or warn "Warn: can't open $mbox_file:$!\n";
    if (!-e $aptg_maildir) {
         print "no such path\n";
         exit;
    }
    while (<MBOX>) {
        chomp;
        if (/^From .*$/) {
            close(MDIR);
            $mdir_file = sprintf("%s/%d.%05d%d.00000000.00.00.%s",
                           $aptg_maildir, time(), rand(10000), $i, $mhost);
            open(MDIR, ">$mdir_file") or warn "can't open $mdir_file:$!\n";
        }
        print MDIR $_, "\n";
    }
    close(MBOX);
    close(FILE);
    system "rm $transfer_tmpdir/$mbox_file 2>/dev/null";
    print STDOUT "Info: $old_account\@$old_host->$new_account OK!\n";
}
