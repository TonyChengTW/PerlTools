#!/usr/bin/perl
# ======================================================
# Writer   : Mico Cheng
# Version  : 20050104
# Use for  : Add to DenyIP
# Host     : 210.200.211.3
# ======================================================
if ($#ARGV != 1)
{
	     print "\nusage:    denyip <reason> <deny-ip> \n";
			      exit;
}


use DBI;
use Socket;

$dbh = DBI ->connect("DBI:mysql:mail_db;host=210.200.211.3", "rmail", "LykCR3t1") or die "$!\n";

$reason = $ARGV[0];
$denyip = $ARGV[1];

$packed_address = inet_aton("$denyip");
$name = gethostbyaddr($packed_address,AF_INET);

print "$denyip\t$name\nAdd this IP (Y/n)? ";
$return = <STDIN>;
chomp($return);

if ($return eq 'y' || $return eq '') {
	    $sqlstmt = sprintf("select * from DenyIP where s_ip='%s'",$denyip);
			    $sth=$dbh->prepare($sqlstmt);
					    $sth->execute();
							    if ($sth->rows!=1) {
										        $sqlstmt = sprintf("\ninsert into DenyIP values ('%s', NOW(), '%s')", $denyip, $reason);
														        print "$sqlstmt \n\n";
																		        $dbh->do($sqlstmt);
																						        exit;
																										    } else {
																													        ($s_ip, $s_time, $s_reason)=($sth->fetchrow_array)[0,1,2];
																																	        print "\n This IP have been already insert earler!\n\n";
																																					        print "$s_ip | $s_time | $s_reason\n\n\n";
																																									        exit;
																																													    }
} else {
	    print "never mind\n";
}
