#!/usr/local/bin/perl
#========================
#Writer :    Mico Cheng
#Version:    20041220
#use for:    kill illegal subject from login failure
#host   :    pop
#=======================
die "rm_illegal_subject.pl /mnt/ms0x/a/b/abc/Maildir/new\n" if (@ARGV != 1);
$s_mailbox = $ARGV[0];
opendir DH, $s_mailbox or die "Can't open $s_mailbox:$!\n";
chdir $s_mailbox;
foreach $file (readdir DH) {
     next if ($file =~ /^\./);
     open FH, $file or warn "Can't open $file:$!\n";
		 while (<FH>) {
			     chomp;
			     if ( $_ =~ /^Subject: (\w+\s+){20,}/) {
                system "rm -f $file";
								print "rm -f $file\n";
           } 
					 if ($_ =~ /<&.*\@.*>/) {
						    system "rm -f $file";
								print "rm -f $file\n";
					 }
	   }
		 close FH;
}
closedir DH;
