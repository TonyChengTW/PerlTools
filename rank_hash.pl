#!/usr/local/bin/perl
#--------------------------------
# Writer :  Mico Cheng
# Version:  2005011301
# Use for:  Ranking hash
# Hosts:    x
#-------------------------------
use Socket;

$maillog_file = shift;

#Check file if exists
#die "Error! $maillog_file not found!\n" until -s $maillog_file;

open OUT1,"$maillog_file" or die "can't open :$!\n";

# data insert into hash
while (<OUT1>) {
	   chomp;
		    $connect_ip = $_;
				   ++$ip_count{$connect_ip};
}
close OUT1;

# Sort and print
printf "-- Start --\n";
printf "IP \t\tFQDN\t\t\t\tConnection Count\t\tDate : $search_date\n";
printf "-----------------------------------------------------------\n";
foreach $key (sort {$ip_count{$b} <=> $ip_count{$a}} %ip_count) {
#	    if ($nowtop == $ntop) { last; };
			    next if ($key =~ /^[0-9]+$/);
					 # Forward DNS lookup
					    $packed_address = inet_aton("$key");
							    $fqdn = gethostbyaddr($packed_address,AF_INET);
									    $fqdn = 'null' until (defined($fqdn));
											    $source = $key."  $fqdn";
													    &result_print($source, $ip_count{$key});
}

print "-- Ending --\n";
#-------------  Functions ----------------
sub result_print {
	 my($lhs,$rhs) = @_;
	  printf "$lhs\t\t$rhs\n";
		 $nowtop++;
}
