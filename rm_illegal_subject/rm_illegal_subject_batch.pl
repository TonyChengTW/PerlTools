#!/usr/local/bin/perl
#========================
#Writer :    Mico Cheng
#Version:    20041220
#use for:    kill illegal subject from login failure(batch)
#host   :    pop
#=======================
die "/mico/rm_illegal_subject/rm_illegal_subject_batch.pl msxx\n" if (scalar(@ARGV)!=1);
$mhost = $ARGV[0];
$crack_file = "/export/home/mico/rm_illegal_subject/crack_file.list";
@file_list = `find /export/$mhost/mbox/[0-9] -mtime -5 -type f -name [0-9]*`;
foreach $file (@file_list) {
	  open CRACK_FILE, ">> $crack_file";
    open FH, $file;
    while (<FH>) {
        chomp;
        if ( $_ =~ /^Subject: (\w+\s+){20,}/) {
            system "mv $file /export/home/mico/rm_illegal_subject/";
						print CRACK_FILE "$file\n";
        }
    }
    close FH;
	  close CRACK_FILE;
}

@file_list = `find /export/$mhost/mbox/[a-z] -mtime -5 -type f -name [0-9]*`;
foreach $file (@file_list) {
    open FH, $file;
    while (<FH>) {
        chomp;
        if ( $_ =~ /^Subject: (\w+\s+){20,}/) {
            system "mv $file /export/home/mico/rm_illegal_subject/";
						print CRACK_FILE "$file\n";
        }
    }
    close FH;
	  close CRACK_FILE;
}
