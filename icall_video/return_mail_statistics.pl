#!/usr/local/bin/perl
#----------------------------------------------
# Version : 2006033101
# Writer  : Miko Cheng
# Use for : ��h�H��icallvideo_cs��, �N�h�H��T�O����DB02��,�t�~�]�N��H��s��MS01�����w�ؿ���
# Host    : ms01 (�b�� : icall_return)
# Progress : �h�H --> icallvideo_cs --> icall_step1 & icall_step2 -->
#            ����H����R�{��(icall_step1) ���R �h�H���e(icall_step2) -->
#            �N��T�g�J db02.aptg.net	
#-----------------------------------------------
# icallvideo_cs   .forward: 
# ipvoip-apol@apol.com.tw;jill@apol.com.tw;ccleader-apol@aptg.com.tw;icall_step1@aptg.net;icall_step2@aptg.net
#-----------------------------------------------
# icall_step1     .forward:
# |/mnt/ms01/i/c/icallvideo_cs/return_mail_statistics.sh
#-----------------------------------------------
use strict;
use DBI;

#sleep 3;  #�O�I�_��,���F���H����g�i��,�ҥH���Ȱ�N���A�}�l���R�H��

my $db02_host = 'db02.aptg.net';
my $db02_user = 'rmail';
my $db02_passwd = 'xxxxxxx';
my $db02_db = 'mail_db';

# �s�@�������
my %monthNums = qw(
    Jan  01 Feb  02 Mar  03 Apr  04 May  05 Jun 06 
    Jul  07 Aug  08 Sep  09 Oct  10 Nov 11 Dec 12);

my $mdir = "/mnt/ms01/i/c/icall_step2/Maildir/new";
my $reserve_bounce_dir = "/export/home/rmail/htdocs/icall_bounce";

my $dsn = sprintf("DBI:mysql:%s;host=%s", $db02_db, $db02_host);
my $dbh = DBI->connect($dsn, $db02_user, $db02_passwd) || die_db($!);

# ����H�󤺮e
my @files = glob "$mdir/*";
if (scalar @files == 0) {
	  print "$mdir is empty! Abort program!\n";
		exit 0;
}

opendir DH, $mdir or die "Error: Can't open $mdir\n";
foreach (readdir DH) {
	  my $total_line; #���N total_line �إߦb foreach �϶��ܼƧ@�νd��
	  next if $_ eq ".." or $_ eq "..";
		my $ab_bounce_file = $mdir.'/'.$_;
		open FH, $ab_bounce_file or die "Error: can't open $ab_bounce_file\n";
    while(<FH>) { $total_line = $total_line.$_; }
		close (FH);
		
# �� $recipient �P $main_domain
    my($recipient) = ($total_line =~ /\nFinal-Recipient: rfc.*; (.*)\n/m);
		(my $mail_domain = $recipient) =~ s/^.*@//;

# �� $deliver_time
		my($day, $month_c, $year, $hour, $minute, $second)
		 	= ($total_line =~ /\nDate:.*(\d+) (\w\w\w) (\d+) (\d+):(\d+):(\d+) \+0800/m);
		my $month = $monthNums{$month_c};
		my $deliver_time = sprintf("%4d%02d%02d%02d%02d", $year, $month, $day, $hour, $minute, $second);

# �� $reason
		$_ = $total_line;s/\n//g;my $total_no_line = $_;
    my($reason) = ($total_no_line =~ /Diagnostic-Code:.*Sachiel; (.*)Content-Description/);

# �L�X�Ҧ����
		print "-------------------------------------------\n";
		print "open $ab_bounce_file\n";
		print "\$recipient:$recipient\n";
    print "\$mail_domain:$mail_domain\n";
		print "\$deliver_time:$deliver_time\n";
		print "\$reason:$reason\n";

# �g�J��Ʈw
		my $sqlstmt = sprintf("INSERT INTO icall (deliver_time,bounce_time,recipient,reason,mail_domain) VALUES( '%s',NOW(),'%s','%s','%s')",$deliver_time, $recipient, $reason, $mail_domain);
    $dbh->do($sqlstmt);
#		print "$sqlstmt\n";

# �h���h�H�� MS01 ��$reserve_bounce_dir/$eml_file �H�Q VOIP ���u�U���h�H�T��.
  $sqlstmt = sprintf("SELECT sn FROM icall WHERE deliver_time='%s' AND recipient='%s'", $deliver_time, $recipient);
		my $sth = $dbh->prepare($sqlstmt);
		$sth->execute();
		if ($sth->rows == 0) {
			  print "Can't find bounce file, exit!!\n";
				$dbh->disconnect();
				exit 0; #�䤣�� sn ,�N��h�H���H�󦳰��D
    } else {
			  while(my @sn = $sth->fetchrow_array) {
					  my ($sn) = (@sn);
            my $eml_file = $sn.'.eml';
            system ("mv $ab_bounce_file $reserve_bounce_dir/$eml_file");
						chown "nobody", "nogroup", "$reserve_bounce_dir/$eml_file";
        }
    }
    undef($total_line);
}
close (DH);
$dbh->disconnect();
