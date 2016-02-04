#!/bin/perl 
# ====================================================== 
# Writer   : Mico Cheng 
# Version  : 2004052501 
# Use for  : transfer IP Class to TrustIP Table 
# ====================================================== 

use DBI; 

$accessfile = shift;

$dbh = DBI ->connect("DBI:mysql:mail_db;host=210.200.211.3", "rmail", 
"xxxxxxx") or die "$!\n"; 


open ACCESS, "$accessfile" or die "Can not open $accessfile:$!\n"; 
foreach (<ACCESS>) { 
      if (/^(.*?)\s+/) { 
            #print "insert $trustip\n"; 
            &insertip($1); 
      } else { 
            print "no match RELAY:$_\n"; 
      } 
} 
$dbh->disconnect(); 
close(ACCESS); 

sub insertip { 
 $sqlstmt = sprintf("insert into DenyMailfrom values ('%s', NOW(), 'from daily report and too many error')", $_[0]); 
 print "$sqlstmt\n";
 $dbh->do($sqlstmt); 
} 

