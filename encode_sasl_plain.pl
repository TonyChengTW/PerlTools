#!/usr/bin/perl

use strict;
use MIME::Base64;

if ( $#ARGV != 1) {
   die "Usage: encode_sasl_plain.pl <username> <password>\n";
}

print encode_base64("$ARGV[0]\0$ARGV[0]\0$ARGV[1]");
exit 0;
