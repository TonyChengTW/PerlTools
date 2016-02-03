#! /usr/local/bin/perl


die "<log> <orig_list>" if (scalar(@ARGV)!=2);

($log_file, $list_file)=@ARGV;

open(FH, $log_file);
while(<FH>) {
	chomp();
	($id)=(split(/\s+/,$_))[0];
	$hash{$id}=1;
}
close(FH);

open(FH, $list_file);
while(<FH>) {
	chomp();
	($id, $pass)=split(/,/, $_);
	if ($hash{$id}!=1) {
		print $_, "\n";
	}
}

close(FH);
