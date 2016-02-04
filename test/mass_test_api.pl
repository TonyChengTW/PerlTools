#! /usr/local/bin/perl
#  ----------------------------------
#   Writer  : Mico Cheng 
#   Version : 2004092001
#   Use for : 
#             1. Checking exist or non-exist Mail & Create non-exit Mail
#             2. add forward E-Mail
#   Host : x
#  ----------------------------------
use IO::Socket;
use DBI;

## -----------------    db01.aptg -----------------------
$db_db01_ip = '210.200.211.3';
$db_db01_account = 'rmail';
$db_db01_pwd = 'xxxxxxx';
$db_db01_name = 'mail_db';

###----------------------------  Check & Add User
 
$dbh_db01=DBI->connect("DBI:mysql:$db_db01_name;host=$db_db01_ip", $db_db01_account,$db_db01_pwd) or die "$!\n";

print "Info: Checking new E-Mail account..............\n";


$cnt = 0;
while ($cnt < 1000) {
     $cnt++;
     $s_mailid = "micocheng_"."$cnt";
     $s_passwd = "micocheng_"."$cnt";
     &insertmail($s_mailid,$s_passwd);
}
#--------------  subrotine --------
sub insertmail {
    my($mail_account, $mail_passwd) = @_;

    $sock_target=IO::Socket::INET->new(PeerAddr        => '210.200.211.3',
                                       PeerPort        => '9999',
                                       Type            => SOCK_STREAM,
                                       Proto           => 'tcp')
        	 or die "can't open socket : $@\n";

    $sock_target->autoflush(1);
    
    # Check Welcome banner
    $buf=<$sock_target>;chomp($buf); $buf=~s/\r//g;
    if ($buf =~ /\+OK/) {
        print $sock_target "adduser\n";
    } else {
        print STDOUT "Error: while create $mail_account,establish fail:$buf\n";
        next;
    }

    #Check adduser parameters
    $buf=<$sock_target>;chomp($buf); $buf=~s/\r//g;
    if ($buf =~ /\+OK/) {
        print STDOUT "$buf\n";
        print $sock_target "$mail_account $mail_passwd aptg.net ms04\n";
        $buf=<$sock_target>;chomp($buf); $buf=~s/\r//g;

    #Check Submit
        if ($buf =~ /\+OK/) {
             print STDOUT "$buf\n";
             print $sock_target "go\n";
             $buf=<$sock_target>;chomp($buf); $buf=~s/\r//g;
             if ($buf =~ /\+OK/) {
                 print STDOUT "$buf\n";
                 print STDOUT "$cnt: Create Successful!\n";
                 next;
             } else {
                 print STDOUT "$buf\n";
                 next;
             }
        } else {
             print STDOUT "$buf\n";
             next;
        }
    } else {
         print STDOUT "$buf\n";
         next;
    }
    close ($sock_target);
}
