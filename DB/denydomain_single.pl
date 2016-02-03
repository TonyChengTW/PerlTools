#!/usr/bin/perl
# ======================================================
# Writer   : Mico Cheng
# Version  : 20050104
# Use for  : Add to DenyDomain
# Host     : 210.200.211.3
# ======================================================
if ($#ARGV != 1)
{
	     print "\nusage:    denydomain <reason> <deny-domain> \n";
			      exit;
}


use DBI;
use Socket;

$dbh = DBI ->connect("DBI:mysql:mail_db;host=210.200.211.3", "rmail", "LykCR3t1") or die "$!\n";

$reason = $ARGV[0];
$denydomain = $ARGV[1];

$packed_address = inet_aton("$denydomain");
$name = gethostbyaddr($packed_address,AF_INET);

print "$denydomain\t$name\nAdd this Domain (Y/n)? ";
$return = <STDIN>;
chomp($return);

if ($return eq 'y' || $return eq '') {
	    $sqlstmt = sprintf("select * from DenyDomain where s_domain='%s'",$denydomain);
			    $sth=$dbh->prepare($sqlstmt);
					    $sth->execute();
							    if ($sth->rows!=1) {
										        $sqlstmt = sprintf("\ninsert into DenyDomain values ('%s', NOW(), '%s')", $denydomain, $reason);
														        print "$sqlstmt \n\n";
																		        $dbh->do($sqlstmt);
																						        exit;
																										    } else {
																													        ($s_domain, $s_time, $s_reason)=($sth->fetchrow_array)[0,1,2];
																																	        print "\n This Domain have been already insert earler!\n\n";
																																					        print "$s_domain | $s_time | $s_reason\n\n\n";
																																									        exit;
																																													    }
} else {
	    print "never mind\n";
}
