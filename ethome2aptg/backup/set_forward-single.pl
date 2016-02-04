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

## ---------------- Variables -----------------------
$old_mail = shift or die "Usage: set_forward-single.pl <old E-mail>\n";

## -----------------    Tercel -----------------------
$db_tercel_ip = '203.79.224.102';
$db_tercel_account = 'brucelai';
$db_tercel_pwd = 'ezmailat60';
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

###----------------------------  Check & Add User
$dbh_db01=DBI->connect("DBI:mysql:$db_db01_name;host=$db_db01_ip", $db_db01_account,$db_db01_pwd) or die "$!\n";

print "\nInfo: Checking new E-Mail account..............\n";

($old_account,$old_host) = ($old_mail =~ /^(.*)@(.*?)\..*$/);
$old_account = lc($old_account); $old_host = lc($old_host);

$sqlstmt=sprintf("SELECT new_mail,pwd FROM mailchang_log 
                  WHERE old_mail like '%s\@%s%'",$old_account,$old_host);

$sth=$dbh_tercel->prepare($sqlstmt);
$sth->execute();
if ($sth->rows==0) {
   print "Error: no such old user:$old_mail tranfered to aptg \n";
   exit;
}

while (($s_mailid,$pwd)=($sth->fetchrow_array)[0,1]) {
     ($s_mailid) = ($s_mailid =~ /^(.*)@.*$/);
     $sqlstmt=sprintf("SELECT s_mailid from MailCheck where s_mailid='%s'", $s_mailid);
     $sth_db01=$dbh_db01->prepare($sqlstmt);
     $sth_db01->execute();
     if ($sth_db01->rows==0) {
        print "Info: $s_mailid non-exist,Insert to DB now!\n";
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
        print "Info: $s_mailid is already inserted,Good!\n";
     }
} 

##------------- Forwarding E-Mail by getting mailchang_log DB

print "Info: Setting forwarding..............\n";

$sqlstmt=sprintf("SELECT old_mail,new_mail FROM mailchang_log
                  WHERE old_mail like '%s\@%s%'",$old_account,$old_host);

$sth=$dbh_tercel->prepare($sqlstmt);
$sth->execute();
if ($sth->rows==0) {
   print "Error: no such old user:$old_mail tranfered to aptg \n";
   exit;
}

while (($old_mail,$new_mail)=($sth->fetchrow_array)[0,1]) {
    &addforwarding($old_mail, $new_mail);
} 
$dbh_tercel->disconnect;


#--------------  subrotine --------
sub addforwarding {
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
             print STDOUT "Info: $cnt/$rows $old_mail->$new_mail OK!\n";
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
