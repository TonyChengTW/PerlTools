#!/usr/local/bin/perl
#--------------------------------
# Writer :  Mico Cheng
# Version:  2005011301
# Use for:  Ranking smtpd status
# Hosts:    mx & ms & smtp (aptg.net)
#-------------------------------
use Socket;

until ($#ARGV == 2) {
   print "\nUsage:  smtpd_statistics.pl  <search type>  <ntop>  <maillogfile/debugfile>\n";
   print "search type        : mailfrom/ip/error/spammail/spamip\n";
   print "ntop for rank      :  1~ unlimited\n";
   print "maillog/debug file : \n";
   print "   when using 'mailfrom' or 'ip' , please input debug file\n";
   print "   when using 'error' or 'spam*' , please input maillog file\n\n\n";
   exit 1;
}

$type = shift;
$ntop = shift;
$maillog_file = shift;

$nowtop = 0;

#Check file if exists
#die "Error! $maillog_file not found!\n" until -s $maillog_file;

($search_date) = ($maillog_file =~ /(200[5-9]\d{4})/);

# Check ARGV
die "./smtpd_statistics.pl <mailfrom|ip|error|spammail|spamip> <ntop> <maillogfile or debugfile>\n" until ($type =~ /^(mailfrom|ip|error|spammail|spamip)$/);

die "./smtpd_statistics.pl <mailfrom|ip|error|spammail|spamip> <ntop> <maillogfile or debugfile>\n" until ($ntop =~ /^([0-9]+)$/);

print "type = $type\t\t\t";
print "top = $ntop\n";
print "maillog file = $maillog_file\n";

# Open debug file
if ($type eq 'mailfrom' || $type eq 'ip') {
    if ($maillog_file =~ /gz|\*$/) {
        open (OUT1,"gzcat $maillog_file|grep -v 127.0.0.1|grep from |")
                        or die "Can't open program:$!\n";
    } else {
        open (OUT1,"cat $maillog_file|grep -v 127.0.0.1|grep from |")
                          or die "Can't open program:$!\n";
    }

    # data insert into hash
    while (<OUT1>) {
       chomp;
       $line = $_;

       ($time,$qid,$mailfrom,$rcptto,$srcip) = ($line =~ /^\[.* (\d+:\d+):\d+\]\s+.*\{([A-Z0-9]+)\} from \((.*)\) to \((.*)\) \[.*\] (\d+\.\d+.\d+.\d+)$/);
         $mailfrom = $srcip."(null mailfrom)" if ($mailfrom eq '');
         if ($type eq 'mailfrom') {
           ++$mailfrom_count{$mailfrom};
         } elsif ($type eq 'ip') {
                   ++$ip_count{$srcip};
       }
    }
    close OUT1;

    # Sort and print
    if ($type eq 'mailfrom') {
        printf "-- Start --\n";
        printf "Sender \t\t\t\tMail Count\t\tDate : $search_date\n";
        printf "-----------------------------------------------------------\n";
        foreach $key (sort {$mailfrom_count{$b} <=> $mailfrom_count{$a}} %mailfrom_count) {
             if ($nowtop == $ntop) { last; };
             next if ($key =~ /^[0-9]+$/);
             &result_print($key, $mailfrom_count{$key});
        }
    } elsif ($type eq 'ip') {
        printf "-- Start --\n";
        printf "IP \t\tFQDN\t\t\t\tConnection Count\t\tDate : $search_date\n";
        printf "-----------------------------------------------------------\n";
#printf "------------ Total IP Count = $total_ip_count --------------------\n";
        foreach $key (sort {$ip_count{$b} <=> $ip_count{$a}} %ip_count) {
            if ($nowtop == $ntop) { last; };
            next if ($key =~ /^[0-9]+$/);
     # Forward DNS lookup
            $packed_address = inet_aton("$key");
            $fqdn = gethostbyaddr($packed_address,AF_INET);
            $fqdn = 'null' until (defined($fqdn));
            $source = $key."  $fqdn";
            &result_print($source, $ip_count{$key});
        }
    }
} elsif ($type eq 'error') {
    $total_error_count = 0;
    # Check smtpd 'many error'
    if ($maillog_file =~ /gz|\*$/) {
       open (OUT2,"gzcat $maillog_file|grep 'too many errors'|")
            or die "Can't open program:$!\n";
    } else {
       open (OUT2,"cat $maillog_file|grep 'too many errors'|")
            or die "Can't open program:$!\n";
    }
    while (<OUT2>) {
        chomp;
        $line = $_;
        ($errip) = ($line =~ /\[(\d+\.\d+\.\d+\.\d+)\]$/);
        ++$ip_error_count{$errip};++$total_error_count;
    }
    close OUT2;
    printf "-- Start --\n";
    printf "SMTPD Error Count \t\tCount\tDate : $search_date\n";
	printf "------------ Total Error Count = $total_spam_count ---------------\n";
    foreach $key (sort {$ip_error_count{$b} <=> $ip_error_count{$a}} %ip_error_count) {
        if ($nowtop == $ntop) {last;};
        next if ($key =~ /^[0-9]+$/);
        # Forward DNS lookup
        $packed_address = inet_aton("$key");
        $fqdn = gethostbyaddr($packed_address,AF_INET);
        $fqdn = 'null' until (defined($fqdn));
        $source = $key."  $fqdn";
        &result_print($source, $ip_error_count{$key});
    }
} elsif ($type eq 'spammail') {
	  $total_spam_count = 0;
    if ($maillog_file =~ /gz|\*$/) {
        open (OUT3,"gzcat $maillog_file|grep 'SPAM.*Yes'|")
                        or die "Can't open program:$!\n";
    } else {
        open (OUT3,"cat $maillog_file|grep 'SPAM.*Yes'|")
                        or die "Can't open program:$!\n";
    }

        while (<OUT3>) {
           chomp($line = $_);
           ($mailfrom,$score) = ($line =~ /, <(.*)> -> .*, Yes, hits=(\d+.\d+)/);
           if (defined($mailfrom) && defined($score)) {
               $spam_total_score{$mailfrom}+=$score;
					     ++$spam_mail_count{$mailfrom};++$total_spam_count;
						   $spam_avg_score{$mailfrom} = 
								 $spam_total_score{$mailfrom}/$spam_mail_count{$mailfrom};
           }
        }
  close OUT3;
  printf "-- Start --\n";
  printf "Spam From \t\t\tScore Avg\tScore Total\tSpam Count\n Date : $search_date\n";
	printf "------------ Total Spam Count = $total_spam_count ----------------\n";
  foreach $key (sort {$spam_mail_count{$b} <=> $spam_mail_count{$a}} %spam_mail_count) {
     if ($nowtop == $ntop) {last;};
        next if ($key =~ /^[0-9]+\.*[0-9]*$/);
				printf ("%s\t\t%.1f\t\t%.1f\t\t%d\n",$key, $spam_avg_score{$key},
						     $spam_total_score{$key}, $spam_mail_count{$key});
        $nowtop++;
  }
#### Forging #####################################################3
} elsif ($type eq 'spamip') {
	  $total_spam_count = 0;
    if ($maillog_file =~ /gz|\*$/) {
        open (OUT4,"gzcat $maillog_file|")
                        or die "Can't open program:$!\n";
    } else {
        open (OUT4,"cat $maillog_file|")
                        or die "Can't open program:$!\n";
    }

        while (<OUT4>) {
           chomp($line = $_);
           ($mailfrom,$score) = ($line =~ /, <(.*)> -> .*, Yes, hits=(\d+.\d+)/);
           if (defined($mailfrom) && defined($score)) {
               $spam_total_score{$mailfrom}+=$score;
					     ++$spam_mail_count{$mailfrom};++$total_spam_count;
						   $spam_avg_score{$mailfrom} = 
								 $spam_total_score{$mailfrom}/$spam_mail_count{$mailfrom};
           }
        }
  close OUT4;
  printf "-- Start --\n";
  printf "Source IP \tScore Avg\tScore Total\tSpam Count\n Date : $search_date\n";
	printf "------------ Total Spam Count = $total_spam_count ----------------\n";
  foreach $key (sort {$spam_avg_score{$b} <=> $spam_avg_score{$a}} %spam_avg_score) {
     if ($nowtop == $ntop) {last;};
        next if ($key =~ /^[0-9]+\.*[0-9]*$/);
     # Forward DNS lookup
        $packed_address = inet_aton("$key");
        $fqdn = gethostbyaddr($packed_address,AF_INET);
        $fqdn = 'null' until (defined($fqdn));
        $source = $key."  $fqdn";
        &result_print($source, $ip_count{$key});
				printf ("%s\t%s\t\t%.1f\t%.1f\t%d\n",$spam_ip{$key}, $fqdn, $spam_avg_score{$key}, $spam_total_score{$key}, $spam_mail_count{$key});
        $nowtop++;
  }
}

print "-- Ending --\n";
#-------------  Functions ----------------
sub result_print {
         my($lhs,$rhs) = @_;
         printf "$lhs\t\t$rhs\n";
         $nowtop++;
}

sub search_spam_ip {

}
