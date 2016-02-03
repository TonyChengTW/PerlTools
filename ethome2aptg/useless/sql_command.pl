#! /usr/local/bin/perl
#  ----------------------------------
#   Writer : Mico Cheng 
#   Version : 20040913
#   Use for : use SQL command to output the format  of text file
#   Host : x
#  ----------------------------------

use DBI;

## -----------------    Modify Start -----------------------
$db_ip = '203.79.224.102';
$db_account = 'brucelai';
$db_pwd = 'ezmailat60';
$db_name = 'dialup';
## -----------------    Modify End   -----------------------

die "./sql_command.pl <action> <txt file>\n" if (scalar(@ARGV)!=2);

$action = $ARGV[0];
$delimiter = "\t";
$file = $ARGV[1];

if ($action eq 'select') {
    open (OUTFH,">$file") or die "Can't create $file:$!\n";
} elsif ($action eq 'modify') {
    open (INFH,"$file") or die "Can't open $file:$!\n";
} else {
    print "Please input <action> by \'select\' or \'modify\'\n";
    exit;
}

$dbh=DBI->connect("DBI:mysql:$db_name;host=$db_ip", $db_account,$db_pwd) or die "$!\n";

#####
if ($action eq 'select') {
    #  Modify 
    $sqlstmt=sprintf("SELECT old_mail,new_mail FROM mailchang_log 
                      WHERE old_mail like '%\@ethome.net.tw'
                      AND m_id>=2283 AND m_id<=2728");
    #$sqlstmt=sprintf("SELECT new_mail FROM mailchang_log 
    #                  WHERE m_id>=2283 AND m_id<=2728");
    $sth=$dbh->prepare($sqlstmt);
    $sth->execute();
    if ($sth->rows==0) {
       print "0 rows in set\n";
       exit;
    }
    #  Modify
    while (($old_mail,$new_mail)=($sth->fetchrow_array)[0,1]) {
    #while (($new_mail)=($sth->fetchrow_array)[0]) {
        print OUTFH "$old_mail"."$delimiter"."$new_mail"."\n";
        #print OUTFH "$new_mail"."\n";
    }
} else {
  ## ---------------    Modify Start -----------------------
  ##
  ## Query User's Password
  ##
    while(<INFH>) {
        chomp;
        $sqlstmt=sprintf("delete from MailCheck where s_mailid='%s' and s_domain=%d", s_mailid, $domain_id);
        $dbh->do($sqlstmt);
    }
}
  ## -----------------    Modify End   -----------------------
close(OUTFH);
close(INFH);
