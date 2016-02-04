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
print "line: $_\n"; 
      if (/^(\d+\.\d+\.\d+\.\d+)\s*/) { 
            #print "insert $trustip\n"; 
            &insertip($1); 
      } elsif (/^(\d+\.\d+\.\d+)\s*/) { 
            @range = 1..254; 
            $trustcip = $1; 
            foreach $one (@range) { 
                   $trustip = "$trustcip."."$one"; 
                   #print "insert $trustip\n"; 
                   insertip($trustip); 
            } 
      } elsif (/^(\d+\.\d+)\s$/) { 
            @range_a = 0..254; 
            @range_b = 1..254; 
            $trustbip = $1; 
            foreach $one (@range_a) { 
                 foreach $two (@range_b) { 
                        $trustip = "$trustbip."."$one."."$two"; 
                        #print "insert $trustip\n"; 
                        insertip($trustip); 
                 } 
            } 
      } else { 
            print "no match RELAY:$_\n"; 
      } 
} 
$dbh->disconnect(); 
close(ACCESS); 

sub insertip { 
#  $sqlstmt = sprintf("select s_ip from TrustIP where s_ip=\'%s\'", $_[0]); 
#  $sth = $dbh->prepare($sqlstmt); 
#  $sth->execute() or die "can not insert : $!\n"; 
#  if ($sth->rows != 1) { 
        $sqlstmt = sprintf("insert into DenyIP values ('%s', NOW(), 'daily routine: too many connections or errors')", $_[0]); 
        $dbh->do($sqlstmt); 
#  } else { 
#        next; 
#  } 
} 

