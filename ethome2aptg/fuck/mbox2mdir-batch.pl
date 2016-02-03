#!/usr/local/bin/perl
#  ----------------------------------
#   Writer  : Mico Cheng
#   Version : 2004100101
#   Use for :
#   Host : x
#  ----------------------------------
# open file

open (FH,"ethome.list") or die "$!\n";


# Check Point

while (<FH>)
	  $line = $_;
    ($old_mail,$new_mail) = ($line =~ /^(.*):(.*)$/);
    ($old_account,$old_host) = ($old_mail =~ /^(.*)@(.*?)\..*$/);
    $old_account = lc($old_account);
		$new_mail = lc($new_mail);
    printf "Info: mkdir $old_account forward to $new_mail\n";
    $s_mbox=sprintf("/export/home/users/%s/%s", substr($old_account, 0, 1), $old_account);
    system("mkdir $s_mbox");
    system("echo $new_mail>$s_mbox/.forward");
    system("/usr/local/bin/chmod -R 755 $new_mail");
}
