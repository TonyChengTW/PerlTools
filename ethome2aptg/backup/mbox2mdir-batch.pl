#!/usr/local/bin/perl
#  ----------------------------------
#   Writer  : Mico Cheng
#   Version : 2004100101
#   Use for :
#   Host : x
#  ----------------------------------
use Net::FTP;
use DBI;

## ---------------- Variables -----------------------
$aptg_deep1_maildir = "/mnt";
$transfer_tmpdir = "/mico/ethome2aptg/tmp";
$cnt = 1;
$| = 1;
$mhost = 'ms04';

## --------------- db01.aptg --------------------------
$db01_ip = '210.200.211.3';
$db01_account = 'rmail';
$db01_pwd = 'LykCR3t1';
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
$cm1_account = 'ftpuser';
$cm1_pwd = 'U83cjo$';
$cm1_deep1_maildir = '/';
$cm1_mbox_file = 'mbox';

$hc_ip = '210.58.94.31';
$hc_account = 'ftpuser';
$hc_pwd = 'U83cjo$';

#-------------------------------------------------------------
# Open Tercel
$dbh_tercel=DBI->connect("DBI:mysql:$tercel_name;host=$tercel_ip", $tercel_account,$tercel_pwd) or die "$!\n";


# Open db01.aptg.net
$dbh_db01=DBI->connect("DBI:mysql:$db01_name;host=$db01_ip", $db01_account,
                        $db01_pwd) or die "$!\n";

# Check Point
$sqlstmt=sprintf("SELECT max(m_id) from mailchang_log");
$sth=$dbh_tercel->prepare($sqlstmt);
$sth->execute();

chomp(($start) = `cat /mico/ethome2aptg/check_point_mbox2mdir.log`);
($end)=($sth->fetchrow_array)[0];

printf "Info: mbox to mdir Check Point Starting at\t $start\nInfo: mbox to mdir Check Point End at\t\t $end\n\n";

if ($start >= $end) {
   print "Warn: No Data to process.Check Point issue, exit program!\n";
   exit;
}

$sqlstmt=sprintf("SELECT count(new_mail) FROM mailchang_log
                  WHERE m_id>=%s AND m_id<=%s", $start, $end);
$sth=$dbh_tercel->prepare($sqlstmt);
$sth->execute();
($rows) = ($sth->fetchrow_array)[0];

###----------------------------   Check & Add User------------------
print "\nInfo: Checking new E-Mail account..............\n\n";

$sqlstmt=sprintf("SELECT new_mail,pwd FROM mailchang_log 
		              WHERE m_id>=%s AND m_id<=%s", $start, $end);
$sth=$dbh_tercel->prepare($sqlstmt);
$sth->execute();
if ($sth->rows==0) {
     print "Error: 0 rows for Add users!\n";
     exit;
}

$cnt = 0;
while (($s_mailid,$pwd)=($sth->fetchrow_array)[0,1]) {
    $cnt++;
    ($s_mailid) = ($s_mailid =~ /^(.*)@.*$/);
    $sqlstmt=sprintf("SELECT s_mailid FROM MailCheck 
				              WHERE s_mailid='%s'", $s_mailid);
    $sth_db01=$dbh_db01->prepare($sqlstmt);
    $sth_db01->execute();
  if ($sth_db01->rows==0) {
    print "Info: Process:$cnt/$rows $s_mailid non-exist,Insert to DB now!\n";
    $s_mbox=sprintf("%s/%s/%s", substr($s_mailid, 0, 1), substr($s_mailid, 1, 1)
                     , $s_mailid);
    $sqlstmt = sprintf("INSERT INTO MailCheck VALUES('%s','1','ms04','%s','0')"
                       , $s_mailid, $s_mbox);
    $dbh_db01->do($sqlstmt) or die "can't insert to MailCheck:$!\n";
    $sqlstmt = sprintf("INSERT INTO MailPass VALUES('%s','1',ENCRYPT('%s'),'%s'
                        ,NOW()", $s_mailid, $pwd, $pwd);
    $dbh_db01->do($sqlstmt) or die "can't insert to MailPass:$!\n";

    # making directory
    $aptg_maildir = sprintf("/mnt/%s/%s/%s/%s/Maildir/new/", $mhost, 
                  substr($s_mailid, 0, 1), substr($s_mailid, 1, 1), $s_mailid);

    $deep2_dir = sprintf("/mnt/%s/%s", $mhost, substr($s_mailid, 0, 1));

    system("mkdir -p $aptg_maildir") or warn "can't mkdir $aptg_maildir:$!\n";
	 	system("/usr/local/bin/chown -R rmail:rmail $deep2_dir");
    #system("/usr/local/bin/chmod -R 755 $deep2_dir");
  } else {
    print "Info: Process:$cnt/$rows $s_mailid is already inserted,Good!\n";
  }
}
#################   Ready to Transfer mbox --> mdir #########
print "\n\nInfo: Beginning Transfering Mailbox -> Maildir..........\n\n";

$sqlstmt=sprintf("SELECT old_mail,new_mail FROM mailchang_log
                  WHERE m_id>=%s AND m_id<=%s", $start, $end);

$sth=$dbh_tercel->prepare($sqlstmt);
$sth->execute();
if ($sth->rows==0) {
   print "Warn: check point error : m_id>$end or m_id <$start \n";
   exit;
}
$cnt = 1;
while (($old_mail,$new_mail)=($sth->fetchrow_array)[0,1]) {
    ($new_account) = ($new_mail =~ /^(.*)@.*$/);
    ($old_account,$old_host) = ($old_mail =~ /^(.*)@(.*?)\..*$/);
    $old_account = lc($old_account); $old_host = lc($old_host);
		$new_account = lc($new_account);
    $aptg_maildir = sprintf("/mnt/%s/%s/%s/%s/Maildir/new/", $mhost, 
                        substr($new_account, 0, 1), substr($new_account, 1, 1),
									      $new_account);

    $aptg_deep2_maildir = sprintf("/mnt/%s/%s/%s", $mhost, 
                        substr($new_account, 0, 1), substr($new_account, 1, 1));
# Create FTP object
    print STDOUT "Info: $cnt/$rows $old_account\@$old_host->$new_account ....";
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
            print "$old_account didn't need convert\n";
						$cnt++;
            next;
        }
        &mbox2mdir($ethome_mbox_file,$aptg_maildir,$mhost);
        system("/usr/local/bin/chown -R rmail:rmail $aptg_deep2_maildir");
        next;
    } elsif ($old_host eq 'cm1') {
        $cm1_maildir = sprintf("%s/%s/%s",$cm1_deep1_maildir,
                                   substr($old_account,0,1),$old_account);
        $cm1_ftp = Net::FTP->new($cm1_ip) 
                              or die "can't connect to $old_host:$@\n";
        $cm1_ftp->login($cm1_account,$cm1_pwd)
                              or warn "$cm1_ftp->message";
        $cm1_ftp->ascii or warn "$cm1_ftp->message";
        $cm1_ftp->cwd($cm1_maildir) or warn "Warn: $cm1_ftp->message";
        $cm1_ftp->get($cm1_mbox_file) or warn "Warn: $cm1_ftp->message :$!";
        $cm1_ftp->quit;
        if (-z $cm1_mbox_file) {
            print "$old_account didn't need convert\n";
						$cnt++;
            next;
        }
        &mbox2mdir($cm1_mbox_file,$aptg_maildir,$mhost);
        system("/usr/local/bin/chown -R rmail:rmail $aptg_deep2_maildir");
        next;
    } elsif ($old_host eq 'hc') {
        $hc_mbox_file = $old_account;
        $hc_ftp = Net::FTP->new($hc_ip)
                              or die "can't connect to $old_host:$@\n";
        $hc_ftp->login($hc_account,$hc_pwd)
                              or warn "$hc_ftp->message";
        $hc_ftp->ascii or warn "$hc_ftp->message";
        $hc_ftp->get($old_account);
        $hc_ftp->quit;
        if (-z $hc_mbox_file) {
	            print "$old_account didn't need convert\n";
	            $cnt++;
	            next;
        }

        &mbox2mdir($hc_mbox_file,$aptg_maildir,$mhost);
        system("/usr/local/bin/chown -R rmail:rmail $aptg_deep2_maildir");
        next;
    } else {
        print "Warn: unknown host --> $old_account\@$old_host\n";
        next;
    }
}
system "echo $end>/mico/ethome2aptg/check_point_mbox2mdir.log";

sub mbox2mdir {
    ($mbox_file, $aptg_maildir, $mhost) = @_;
    open MBOX, "$transfer_tmpdir/$mbox_file" or warn "Warn: can't open $mbox_file:$!\n";
    if (!(-e $aptg_maildir) || !(-e "$transfer_tmpdir\/$mbox_file")) {
         print "no such path($aptg_maildir) or file($mbox_file)\n";
#exit;
				 next;
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
    print STDOUT " OK!\n";
    $cnt++;
}
