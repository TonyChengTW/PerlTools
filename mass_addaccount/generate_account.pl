#!/usr/local/bin/perl
open ACCOUNT,">account.list";
$i=1;
while ($i < 1024) {
	print ACCOUNT "micocheng_$i\n";
	$i++;
}
