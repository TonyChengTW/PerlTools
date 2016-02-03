#! /usr/local/bin/perl

use DBI;

require "/export/home/rmail/bin/config.pl";

die "./dispatch_list.pl <file> <host_limit> <file_limit>" if (scalar(@ARGV)!=3);
($filename, $host_limit, $file_limit)=@ARGV;

die "$filename is not exist!" if (!-e $filename);

## 取得全部hostname, 跟目前的量, 還有目前已經存在的id
@hosts=();
%hosts_count=();
%account=();
%final_result=();

$dsn=sprintf("DBI:mysql:%s;host=%s", $DB{'mta'}{'name'}, $DB{'mta'}{'host'});
$dbh=DBI->connect($dsn, $DB{'mta'}{'user'}, $DB{'mta'}{'pass'})
  || die_db($!);
$sqlstmt="select s_hostname from HostMap";
$sth=$dbh->prepare($sqlstmt);
$sth->execute();
$sth->bind_col(1, \$s_hostname);
while ($sth->fetch) {
	push(@hosts, $s_hostname);
}

foreach $host (@hosts) {
	$sqlstmt=sprintf("select count(*) from MailCheck where s_mhost='%s'", $host);
	$sth=$dbh->prepare($sqlstmt);
	$sth->execute();
	$sth->bind_col(1, \$cnt);
	$sth->fetch;
	$hosts_count{$host}=$cnt;
}

$sqlstmt="select s_mailid from MailCheck";
$sth=$dbh->prepare($sqlstmt);
$sth->execute();
$sth->bind_col(1, \$s_mailid);
while ($sth->fetch) {
	$s_mailid=lc($s_mailid);
	$account{$s_mailid}=1;
}

undef $sth;
$dbh->disconnect();

open(FH, "<$filename");
open(ERR, ">error.log");

while(<FH>) {
	chomp();
	($id, $pass)=split(/,/,$_);
	$id=lc($id); # 全部要小寫
	# 有問題的寫到另一個檔案去
	if (check_account($id)==0 || length($pass)==0) {
		print ERR $_, "\n";
		next;
	}

	if ($account{$id}==1) {
		## 這個帳號已經存在了 -_-b
		print ERR $_, "\n";
		next;
	}


	## 選host, 但是不能超出host上限
	$valid=0;
	$select_host='';
	do {
		$select_host=$hosts[int(rand(scalar(@hosts)))];
		if ($hosts_count{$select_host} >= $host_limit) {
			$valid=0;
		} else {
			$valid=1;
		}
	} while ($valid==0);
	$tag=sprintf("%s,%s,%s", $id, $pass, $select_host);
	$final_result{$tag}=1;
}
close(FH);
close(ERR);

# do final write list
%file_count=();
foreach $key (keys %final_result) {
	($id, $pass, $host)=split(/,/,$key);
	$file_count{$host}++;
	$listfile=sprintf("list.%s.%03d", $host, int($file_count{$host}/($file_limit+1)));
	open(LIST, ">>$listfile");
	print LIST "$id,$pass\n";
	close(LIST);
}


exit;

sub check_account {
	$acc=$_[0];

	if (length($acc)>1 && $acc =~ /([a-z0-9_])([a-z0-9_])([a-z0-9\_\.])?/) {
		return 1;
	} else {
		return 0;
	}
}
