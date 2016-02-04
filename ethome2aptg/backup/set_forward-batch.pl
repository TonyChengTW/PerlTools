#! /usr/local/bin/perl
#  ----------------------------------
#   Writer  : Mico Cheng 
#   Version : 2004092401
#   Use for : 
#             1. Checking exist or non-exist Mail & Create non-exit Mail
#             2. add forward E-Mail
#   Host : x
#  ----------------------------------
use IO::Socket;
use DBI;

## -----------------    Tercel -----------------------
$db_tercel_ip = '203.79.224.102';
$db_tercel_account = 'brucelai';
$db_tercel_pwd = 'xxxxxxx';
$db_tercel_name = 'dialup';

## -----------------    db01.aptg -----------------------
$db_db01_ip = '210.200.211.3';
$db_db01_account = 'rmail';
$db_db01_pwd = 'xxxxxxx';
$db_db01_name = 'mail_db';

## ----------------    ethome all server's IP and port ---
$sock_ethome_ip = '210.58.94.70';
$sock_cm1_ip = '210.58.94.22';
$sock_hc_ip = '210.58.94.31';
$sock_port = '7878';

## -------------------------------------------------------
die "./set_forward.pl\n" if (scalar(@ARGV)!=0);

# Open Tercel & db01.aptg.net
$dbh_tercel=DBI->connect("DBI:mysql:$db_tercel_name;host=$db_tercel_ip", $db_tercel_account,$db_tercel_pwd) or die "$!\n";


# Check Point
$sqlstmt=sprintf("SELECT max(m_id) from mailchang_log");
$sth=$dbh_tercel->prepare($sqlstmt);
$sth->execute();

chomp(($start) = `cat /mico/ethome2aptg/check_point_forward.log`);
($end)=($sth->fetchrow_array)[0];
printf "Info: Forwarding Check Point Starting at\t $start\nInfo: Forwarding Check Point End at\t\t $end\n\n";

if ($start >= $end) {
   print "Warn: No Data to process.Check Point issue, exit program!\n";
   exit;
}

$sqlstmt=sprintf("SELECT count(new_mail) FROM mailchang_log 
                  WHERE m_id>=%s AND m_id<=%s", $start, $end);
$sth=$dbh_tercel->prepare($sqlstmt);
$sth->execute();
($rows) = ($sth->fetchrow_array)[0];

###----------------------------  Check & Add User
 
#$dbh_tercel=DBI->connect("DBI:mysql:$db_tercel_name;host=$db_tercel_ip", $db_tercel_account,$db_tercel_pwd) or die "$!\n";

$dbh_db01=DBI->connect("DBI:mysql:$db_db01_name;host=$db_db01_ip", $db_db01_account,$db_db01_pwd) or die "$!\n";

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
     $sqlstmt=sprintf("SELECT s_mailid from MailCheck where s_mailid='%s'", $s_mailid);
     $sth_db01=$dbh_db01->prepare($sqlstmt);
     $sth_db01->execute();
     if ($sth_db01->rows==0) {
        print "Info: Process:$cnt/$rows $s_mailid non-exist,Insert to DB now!\n";
        $s_mbox=sprintf("%s/%s/%s", substr($s_mailid, 0, 1), substr($s_mailid, 1, 1), $s_mailid);
        $sqlstmt = sprintf("INSERT INTO MailCheck VALUES('%s','1','ms04','%s','0')", $s_mailid, $s_mbox);
        $dbh_db01->do($sqlstmt) or die "can't insert to MailCheck:$!\n";
        $sqlstmt = sprintf("INSERT INTO MailPass VALUES('%s','1',ENCRYPT('%s'),'%s',NOW()", $s_mailid, $pwd, $pwd);
        $dbh_db01->do($sqlstmt) or die "can't insert to MailPass:$!\n";
        
        # making directory
        $aptg_maildir = sprintf("/mnt/ms04/%s/%s/%s/Maildir/new/", substr($s_mailid, 0, 1), substr($s_mailid, 1, 1), $s_mailid);

        $deep2_dir = sprintf("/mnt/ms04/%s", substr($s_mailid, 0, 1));

        system("mkdir -p $aptg_maildir") or warn "can't mkdir $aptg_maildir:$!\n";
        system("/usr/local/bin/chown -R rmail:rmail $deep2_dir");
        #system("/usr/local/bin/chmod -R 755 $deep2_dir");
     } else {
        print "Info: Process:$cnt/$rows $s_mailid is already inserted,Good!\n";
     }
} 

##------------- Forwarding E-Mail by getting mailchang_log DB

print "\n\nInfo: Setting forwarding..............\n\n";
$sqlstmt=sprintf("SELECT old_mail,new_mail FROM mailchang_log 
                  WHERE m_id>=%s AND m_id<=%s", $start, $end);
#$sqlstmt=sprintf("SELECT old_mail,new_mail FROM mailchang_log 
#                  WHERE old_mail like '%\@hc.ethome.net.tw'");
#$sqlstmt=sprintf("SELECT old_mail,new_mail FROM mailchang_log 
#                  WHERE old_mail like '%\@ethome.net.tw' limit 5");
$sth=$dbh_tercel->prepare($sqlstmt);
$sth->execute();
if ($sth->rows==0) {
   print "Warn: check point error : m_id>$end or m_id <$start \n";
   exit;
}
$cnt = 1;
while (($old_mail,$new_mail)=($sth->fetchrow_array)[0,1]) {
    print STDOUT "Info: $cnt/$rows $old_mail->$new_mail....";
    &addforwarding($old_mail, $new_mail);
} 
system "echo $end>/mico/ethome2aptg/check_point_forward.log";
$dbh_tercel->disconnect;
#$dbh_db01->disconnect;


#--------------  subrotine --------
sub addforwarding {
    $cnt++;
    my($old_mail, $new_mail) = @_;
    ($old_account,$forwarding_host)= ($old_mail =~ /^(.*)@(\w+)\..*?$/);

    if ($forwarding_host eq 'ethome') {
        $sock_ip = $sock_ethome_ip;
    } elsif ($forwarding_host eq 'hc') {
        $sock_ip = $sock_hc_ip;
    } elsif ($forwarding_host eq 'cm1') {
        $sock_ip = $sock_cm1_ip;
    }

    $sock_target=IO::Socket::INET->new(PeerAddr        => $sock_ip,
                                       PeerPort        => $sock_port,
                                       Type            => SOCK_STREAM,
                                       Proto           => 'tcp')
        	 or die "can't open socket : $!\n";

    $sock_target->autoflush(1);
    
    $buf=<$sock_target>;chomp($buf); $buf=~s/\r//g;
    if (!$buf =~ /\+OK/) {
         print STDOUT "Error: establish fail:$buf\n";
         next;
    } else {
         print $sock_target "addforward\n";
    }
    $buf=<$sock_target>;chomp($buf); $buf=~s/\r//g;
    if ($buf =~ /\+OK/) {
        print $sock_target "$old_account $new_mail\n";
        $buf=<$sock_target>;chomp($buf); $buf=~s/\r//g;
        if ($buf =~ /\+OK/) {
             print $sock_target "quit\n";
             print STDOUT "OK!\n";
        } else {
             print $sock_target "\n";
             print $sock_target "quit\n";
             print STDOUT "Error: $buf  - $old_mail->$new_mail\n"; 
        }
    } else {
        print $sock_target "quit\n";
             print STDOUT "Error: $buf\n";
    }
    close($sock_target);
}
