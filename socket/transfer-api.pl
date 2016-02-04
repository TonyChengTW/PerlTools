#!/usr/local/bin/perl
#  ----------------------------------
#   Writer  : Mico Cheng
#   Version : 2004101401
#   Use for : transfer ethome mbox to mdir && set forwarding by socket
#   Host : pop02.aptg.net
#  ----------------------------------
use Socket;
use IO::Socket;
use Net::FTP;
use DBI;
use POSIX 'WNOHANG';


## ---------------- Variables -----------------------
$my_ip = '210.200.211.17';
$aptg_deep1_maildir = "/mnt";
$transfer_tmpdir = "/mico/ethome2aptg/tmp";
$logfile = "/mico/ethome2aptg/transfer.log";
$| = 1;
$mhost = 'ms04';
$forward_port = '7878';
$transfer_port = '7879';
$protocol = getprotobyname('tcp');
$SIG{INT} = sub { die "Interrupt!\n" };
$SIG{PIPE} = sub { $brokenpipe = 1 };
$SIG{CHLD} = sub { while ( waitpid(-1,WNOHANG) >0 ) {} };

## --------------- db01.aptg --------------------------
$db01_ip = '210.200.211.3';
$db01_account = 'rmail';
$db01_pwd = 'xxxxxxx';
$db01_name = 'mail_db';

## -----------------    Tercel -----------------------
$tercel_ip = '203.79.224.102';
$tercel_account = 'brucelai';
$tercel_pwd = 'xxxxxxx';
$tercel_name = 'dialup';

## -----------------  all ftp ethome -----------------------
$ethome_ip = '210.58.94.74';
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
#
die "Usage:transfer.pl\n" if (scalar(@ARGV)!=0);
open LOG, ">>$logfile" or die "Can't open $logfile:$!\n";
#-----------   Server implementaion ---------------
socket(TRANS_SOCK, AF_INET, SOCK_STREAM, $protocol) or die "socket() failed:$!\n";
setsockopt(TRANS_SOCK, SOL_SOCKET, SO_REUSEADDR, 1) or die "setsockopt() failed:$!\n";
setsockopt(TRANS_SOCK, SOL_SOCKET, SO_KEEPALIVE, 1) or die "setsockopt() failed:$!\n";

$my_packed_ip = inet_aton($my_ip);
$my_addr = sockaddr_in($transfer_port,$my_packed_ip) or die "sockaddr_in() failed:$!\n";

bind(TRANS_SOCK,$my_addr) or die "bind() failed:$!\n";
listen(TRANS_SOCK,SOMAXCONN) or die "listen() failed:$!\n";

print LOG "Info: Ready to listen connections.....\n";
while (1) {
	  next unless $remote_addr = accept(TRANS_SESSION,TRANS_SOCK);
		defined ($child = fork()) or die "Error: fork() failed:$!\n";
		if ($child == 0) {
    		TRANS_SESSION->autoflush(1);
    
    		($remote_port,$remote_packed_ip) = sockaddr_in($remote_addr);
    		$remote_ip = inet_ntoa($remote_packed_ip);
    		$timestamp = time;
    		($sec, $min, $hour, $day, $mon) = (localtime $timestamp)[0, 1, 2, 3, 4];
    		$date = sprintf("%02d/%02d %02d:%02d:%02d", $mon+1, $day, $hour, $min, $sec);
    		print LOG "Info: $date Connection from $remote_ip:$remote_port\n";
    		unless (($remote_ip eq '203.79.224.84') || ($remote_ip eq '203.79.224.100') || ($remote_ip eq '210.200.211.17')) {
            print LOG "Info: $date Access Deny!\n";
    				print TRANS_SESSION "-ERR Access Deny!\n";
            close(TRANS_SESSION);
    				exit;
    		}
    		print TRANS_SESSION "+OK transfer.aptg.net transfer_api v20041014 from $remote_ip\n";
    		$buf = <TRANS_SESSION>;
    		chomp($buf);$buf=~s/\r//g;
        print LOG "Info: $date \$buf=$buf\n";
    
    		if ($buf eq 'help' || $buf eq '?' || $buf eq 'h') {
    			  print TRANS_SESSION "Usage:\n";
    			  print TRANS_SESSION "<old E-mail> <new E-Mail>\n";
    				print TRANS_SESSION "-ERR please reconnect again\n";
            close(TRANS_SESSION);
    			  exit;
    	  } elsif ($buf eq 'quit') {
    			  print TRANS_SESSION "+OK disconnect!\n";
            close(TRANS_SESSION);
    			  exit;
    	  } elsif ($buf =~ /^(\w+(-?\w+|\.?\w+|\w?)\@[\w\.]+\w+,?)+\s+(\w+(-?\w+|\.?\w+|\w?)\@[\w\.]+\w+,?)+$/) {
    			  ($old_mail,$new_mail) = ($buf =~ /^(.*)\s+(.*)$/);
            #-------------------------------------------------------------
            # Open Tercel
            $dbh_tercel=DBI->connect("DBI:mysql:$tercel_name;host=$tercel_ip", $tercel_account,$tercel_pwd) or die "$!\n";
            
            #-------------------------------------------------------------
            # Open db01.aptg.net
            $dbh_db01=DBI->connect("DBI:mysql:$db01_name;host=$db01_ip", $db01_account, $db01_pwd) or die "$!\n";
            
            ###----------------------------   Check & Add User------------------
            print LOG "Info: $date Checking new E-Mail account..............\n";
            
            $sqlstmt=sprintf("SELECT new_mail,pwd FROM mailchang_log 
            		              WHERE new_mail='%s'", $new_mail);
            $sth=$dbh_tercel->prepare($sqlstmt);
            $sth->execute();
            if ($sth->rows==0) {
                 print LOG "Warn: $date not exist in Tercel DB!\n";
            }
            
            while (($s_mailid,$pwd)=($sth->fetchrow_array)[0,1]) {
                ($s_mailid) = ($s_mailid =~ /^(.*)@.*$/);
                $sqlstmt=sprintf("SELECT s_mailid FROM MailCheck 
            				              WHERE s_mailid='%s'", $s_mailid);
                $sth_db01=$dbh_db01->prepare($sqlstmt);
                $sth_db01->execute();
                if ($sth_db01->rows==0) {
                print LOG "Info: $date $s_mailid non-exist,Insert to DB now!\n";
                $s_mbox=sprintf("%s/%s/%s", substr($s_mailid, 0, 1), substr($s_mailid, 1, 1), $s_mailid);
                $sqlstmt = sprintf("INSERT INTO MailCheck VALUES('%s','1','%s','%s','0')", $s_mailid, $mhost, $s_mbox);
                $dbh_db01->do($sqlstmt) or die "can't insert to MailCheck:$!\n";
                $sqlstmt = sprintf("INSERT INTO MailPass VALUES('%s','1',ENCRYPT('%s'),'%s',NOW()", $s_mailid, $pwd, $pwd);
                $dbh_db01->do($sqlstmt) or die "can't insert to MailPass:$!\n";
            
                # making directory
                $aptg_maildir = sprintf("/mnt/%s/%s/%s/%s/Maildir/new/", $mhost, substr($s_mailid, 0, 1), substr($s_mailid, 1, 1), $s_mailid);
            
                $deep2_dir = sprintf("/mnt/%s/%s", $mhost, substr($s_mailid, 0, 1));
            
                system("mkdir -p $aptg_maildir") or warn "can't mkdir $aptg_maildir:$!\n";
            	 	system("/usr/local/bin/chown -R rmail:rmail $deep2_dir");
                #system("/usr/local/bin/chmod -R 755 $deep2_dir");
              } else {
                print LOG "Info: $date $s_mailid is already inserted,Good!\n";
              }
            }
            #################   Ready to Transfer mbox --> mdir #########
            
            ($new_account) = ($new_mail =~ /^(.*)@.*$/);
            ($old_account,$old_host) = ($old_mail =~ /^(.*)@(.*?)\..*$/);
            $old_account = lc($old_account); $old_host = lc($old_host);
            $new_account = lc($new_account);
            $aptg_maildir = sprintf("/mnt/%s/%s/%s/%s/Maildir/new/", $mhost, substr($new_account, 0, 1), substr($new_account, 1, 1), $new_account);
            
            $aptg_deep2_maildir = sprintf("/mnt/%s/%s/%s", $mhost, substr($new_account, 0, 1), substr($new_account, 1, 1));
            # Create FTP object
            chdir($transfer_tmpdir);
            if ($old_host eq 'ethome') {
            		&addforwarding($old_mail, $new_mail);
                print LOG "Info: $date Beginning Transfering Mailbox -> Maildir.\n";
                print LOG "Info: $date $old_account\@$old_host-->$new_account ....";
                $ethome_maildir = sprintf("%s/%s/%s",$ethome_deep1_maildir, substr($old_account,0,1),$old_account);
                $ethome_ftp = Net::FTP->new($ethome_ip) or warn "can't connect to $old_host:$@\n";
                $ethome_ftp->login($ethome_account,$ethome_pwd) or warn "$ethome_ftp->message";
                $ethome_ftp->ascii or warn "$ethome_ftp->message";
                $ethome_ftp->cwd($ethome_maildir) or warn "Warn: $ethome_ftp->message";
                $ethome_ftp->get($ethome_mbox_file) or warn "Warn: $ethome_ftp->message :$!";
                $ethome_ftp->quit;
                if (-z $ethome_mbox_file) {
                    print LOG "Info: $date $old_account didn't need convert\n";
    								print TRANS_SESSION "+OK $old_account didn't need convert old mailbox to aptg.net\n";
                    close(TRANS_SESSION);
                    exit;
                }
                &mbox2mdir($ethome_mbox_file,$aptg_maildir,$mhost);
                system("/usr/local/bin/chown -R rmail:rmail $aptg_deep2_maildir");
    						print TRANS_SESSION "+OK $old_account convert & set forwarding Successful!\n";
                close(TRANS_SESSION);
                exit;
            } elsif ($old_host eq 'cm1') {
            		&addforwarding($old_mail, $new_mail);
                print LOG "Info: $date Beginning Transfering Mailbox -> Maildir.\n";
                print LOG "Info: $date $old_account\@$old_host-->$new_account ....";
                $cm1_maildir = sprintf("%s/%s/%s",$cm1_deep1_maildir, substr($old_account,0,1),$old_account);
                $cm1_ftp = Net::FTP->new($cm1_ip) or warn "can't connect to $old_host:$@\n";
                $cm1_ftp->login($cm1_account,$cm1_pwd) or warn "$cm1_ftp->message";
                $cm1_ftp->ascii or warn "$cm1_ftp->message";
                $cm1_ftp->cwd($cm1_maildir) or warn "Warn: $cm1_ftp->message";
                $cm1_ftp->get($cm1_mbox_file) or warn "Warn: $cm1_ftp->message :$!";
                $cm1_ftp->quit;
                if (-z $cm1_mbox_file) {
                    print LOG "Info: $date $old_account didn't need convert\n";
    								print TRANS_SESSION "+OK $old_account didn't need convert old mailbox to aptg.net\n";
                    close(TRANS_SESSION);
                    exit;
                }
                &mbox2mdir($cm1_mbox_file,$aptg_maildir,$mhost);
                system("/usr/local/bin/chown -R rmail:rmail $aptg_deep2_maildir");
    						print TRANS_SESSION "+OK $old_account convert & set forwarding Successful!\n";
                close(TRANS_SESSION);
                exit;
            } elsif ($old_host eq 'hc') {
            		&addforwarding($old_mail, $new_mail);
                print LOG "Info: $date Beginning Transfering Mailbox -> Maildir.\n";
                print LOG "Info: $date $old_account\@$old_host-->$new_account ....";
                $hc_mbox_file = $old_account;
                $hc_ftp = Net::FTP->new($hc_ip) or die "can't connect to $old_host:$@\n";
                $hc_ftp->login($hc_account,$hc_pwd) or warn "$hc_ftp->message";
                $hc_ftp->ascii or warn "$hc_ftp->message";
                $hc_ftp->get($old_account);
                $hc_ftp->quit;
                if (-z $hc_mbox_file) {
            	      print LOG "Info: $date $old_account didn't need convert\n";
    								print TRANS_SESSION "+OK $old_account didn't need convert old mailbox to aptg.net\n";
                    close(TRANS_SESSION);
            				exit;
                }
            
                &mbox2mdir($hc_mbox_file,$aptg_maildir,$mhost);
                system("/usr/local/bin/chown -R rmail:rmail $aptg_deep2_maildir");
    						print TRANS_SESSION "+OK $old_account convert & set forwarding Successful!\n";
                close(TRANS_SESSION);
                exit;
            } else {
                print LOG "Warn: $date unknown host --> $old_account\@$old_host\n";
                print TRANS_SESSION "-ERR unknown host --> $old_account\@$old_host\n";
                close(TRANS_SESSION);
                exit;
            }
        } else {
    			  print LOG "Error: $date unknow command\n";
    			  print TRANS_SESSION "-ERR unknow command\n";
            close(TRANS_SESSION);
    				exit;
    		}
	  }
		close(TRANS_SESSION);
}    
#--------------  subrotine --------
sub mbox2mdir {
($mbox_file, $aptg_maildir, $mhost) = @_;
open MBOX, "$transfer_tmpdir/$mbox_file" or warn "Warn: can't open $mbox_file:$!\n";
if (!(-e $aptg_maildir) || !(-e "$transfer_tmpdir\/$mbox_file")) {
     print LOG "Error: $date no such path($aptg_maildir) or file($mbox_file)\n";
     print TRANS_SESSION "-ERR no such path($aptg_maildir) or file($mbox_file)\n";
     close(TRANS_SESSION);
     next;
}
while (<MBOX>) {
    chomp;
    if (/^From .*$/) {
        close(MDIR);
        $mdir_file = sprintf("%s/%d.%05d%d.00000000.00.00.%s", $aptg_maildir, time(), rand(10000), $i, $mhost);
        open(MDIR, ">$mdir_file") or warn "can't open $mdir_file:$!\n";
    }
    print MDIR $_, "\n";
}
close(MBOX);
close(FILE);
system "rm $transfer_tmpdir/$mbox_file 2>/dev/null";
print LOG " OK!\n";
}

#--------------  subrotine --------
sub addforwarding {
    print LOG "Info: $date Beginning to Set Forwarding..........\n";
    my($old_mail, $new_mail) = @_;
    ($old_account,$forwarding_host)= ($old_mail =~ /^(.*)@(\w+)\..*?$/);

    if ($forwarding_host eq 'ethome') {
        $sock_ip = $ethome_ip;
    } elsif ($forwarding_host eq 'hc') {
        $sock_ip = $hc_ip;
    } elsif ($forwarding_host eq 'cm1') {
        $sock_ip = $cm1_ip;
    }

    $sock_target=IO::Socket::INET->new(PeerAddr        => $sock_ip,
                                       PeerPort        => $forward_port,
                                       Type            => SOCK_STREAM,
                                       Proto           => 'tcp')
        	 or die "can't open socket : $!\n";

    $sock_target->autoflush(1);
    
    $buf=<$sock_target>;chomp($buf); $buf=~s/\r//g;
    if (!$buf =~ /\+OK/) {
         print LOG "Error: $date establish fail:$buf\n";
         print TRANS_SESSION "-ERR establish fail:$buf\n";
         close(TRANS_SESSION);
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
             print LOG "Info: $date $old_mail->$new_mail forwarding OK!\n"; 
        } else {
             print $sock_target "\n";
             print $sock_target "quit\n";
             print LOG "Error: $date failed in $buf  - $old_mail->$new_mail\n"; 
             print TRANS_SESSION "-ERR failed in $buf  - $old_mail->$new_mail\n"; 
             close(TRANS_SESSION);
             next;
        }
    } else {
        print $sock_target "quit\n";
        print LOG "Error: $date $buf\n";
        print TRANS_SESSION "-ERR $buf\n";
        close(TRANS_SESSION);
        next;
    }
    close($sock_target);
}
close(LOG);
