#!/usr/local/bin/perl
#-----------------------------
# Writer : Mico Cheng
# Version: 2005012501
# Use for: accounting SPAM/VIRUS/TOTAL ratio for mx/ms/smtp
# Host   : mx/ms/smtp
#-----------------------------
die "Usage: mico-statistics.pl <maillog file>\n" until ($#ARGV == 0 );

$mx_sa_tag2_level_deflt = 6.5;
$mx_sa_kill_level_deflt = 6.5;

$smtp_sa_tag2_level_deflt = 5.5;
$smtp_sa_kill_level_deflt = 8;

$maillog_file = $ARGV[0];$_ = $ARGV[0];
s/maillog/maildebug/;
$maildebug_file = $_;

($search_date) = ($maillog_file =~ /(200[5-9]\d{4})/);
($server_type) = ($maillog_file =~ /((smtp|mx|ms)\d*)/);

if ($server_type =~ 'smtp') {
	  $sa_tag2_level_deflt = $smtp_sa_tag2_level_deflt;
	  $sa_kill_level_deflt = $smtp_sa_kill_level_deflt;
} elsif ($server_type =~ 'mx') {
	  $sa_tag2_level_deflt = $mx_sa_tag2_level_deflt;
	  $sa_kill_level_deflt = $mx_sa_kill_level_deflt;
}

$server_type = uc($server_type).' Server';

# Generate SPAM/VIRUS/UNCHK/TOTAL count & Ratio
chomp($_ = `gzcat $maillog_file|grep ', Yes,'|wc -l`);
s/^\s+//;$SPAM_messages = $_;
chomp($_ = `gzcat $maillog_file|grep 'discarded,.*VIRUS'|wc -l`);
s/^\s+//;$VIRUS_messages = $_;
chomp($_ = `gzcat $maillog_file|grep 'message-id'|awk '{print \$10}'|sort|uniq|wc -l`);
s/^\s+//;$TOTAL_messages = $_;
chomp($_ = `gzcat $maillog_file|grep '\] connect'|egrep -v '127.0.0.1|210.200.211.61'|wc -l`);
s/^\s+//;$TOTAL_connections = $_;
chomp($_ = `gzcat $maildebug_file|grep 'not allowed'|wc -l`);
s/^\s+//;$BLOCKED_connections = $_;

$allowed_connections_ratio = ($TOTAL_connections-$BLOCKED_connections)/$TOTAL_connections;
$denied_connections_ratio = $BLOCKED_connections/$TOTAL_connections;

$spam_messages_ratio = $SPAM_messages/$TOTAL_messages;
$virus_messages_ratio = $VIRUS_messages/$TOTAL_messages;

# printing
printf "Date\t\t\t$search_date\n";
printf "Server Type\t\t$server_type\n";
printf "Spam Score Detection\t$sa_tag2_level_deflt\n\n";

printf ("Incoming Connections:\t%d Connections\n", $TOTAL_connections);
printf ("Allowed Connections:\t%d Connections\n", $TOTAL_connections-$BLOCKED_connections);
printf ("Blocked Connections:\t%d Connections\n\n", $BLOCKED_connections);

printf ("Incoming Messages:\t%d messages\n", $TOTAL_messages);
printf ("Clean Messages:\t\t%d messages\n", $TOTAL_messages-$SPAM_messages-$VIRUS_messages);
printf ("Spam Messages:\t\t%d messages\n", $SPAM_messages);
printf ("Virus Messages:\t\t%d messages\n\n\n", $VIRUS_messages);

printf ("   Unhealth Connections Ratio\t%.2f%\n\n\n", $denied_connections_ratio*100);

printf ("   Spam messages Ratio\t\t%.2f%\n", $spam_messages_ratio*100);
printf ("+) Virus messages Ratio\t\t%.2f%\n", $virus_messages_ratio*100);
printf ("   ______________________________________\n");
printf ("   Unhealth Messages Ratio\t%.2f%\n", $spam_messages_ratio*100+$virus_messages_ratio*100);
