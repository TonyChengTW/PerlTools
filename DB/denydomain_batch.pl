#!/bin/perl 
# ====================================================== 
# Writer   : Mico Cheng 
# Version  : 20050215
# Use for  : transfer Domain list to DenyDomain
# ====================================================== 

use DBI; 

$listfile = shift;

$dbh = DBI ->connect("DBI:mysql:mail_db;host=210.200.211.3", "rmail", 
"xxxxxxx") or die "$!\n"; 


open LIST, "$listfile" or die "Can not open $listfile:$!\n"; 
foreach (<LIST>) { 
	    chomp;
      if (/^(.*)\s*/) { 
print "$1 ==> going to insert\n"; 
            &insert($1); 
      } else { 
            print "no match :$_\n"; 
      } 
} 
$dbh->disconnect(); 
close(LIST); 

sub insert { 
  $sqlstmt = sprintf("insert into DenyDomain values ('%s', NOW(), 'from daily report')", $_[0]); 
  $dbh->do($sqlstmt); 
} 

