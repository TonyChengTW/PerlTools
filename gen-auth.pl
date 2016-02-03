#!/usr/bin/perl

use strict;
use MIME::Base64;

my($p_name)   = $0 =~ m|/?([^/]+)$|;
my $p_version = "20031027.2";
my $p_usage   = "Usage: $p_name [--help|--version] | <type> ...";
my $p_cp      = <<EOM;
Copyright (c) 2003
      John Jetmore <jj33\@pobox.com>.  All rights reserved.
This code freely redistributable provided my name and this copyright notice
are not removed.  Send email to the contact address if you use this program.
EOM
ext_usage();

my $type = get_input(\@ARGV, "encryption type: ");

if ($type =~ /^plain$/i) {
  my $user = get_input(\@ARGV, "username: ");
  my $pass = get_input(\@ARGV, "password: ", 1);
  print "Auth String: ", encode_base64("\0$user\0$pass", ''), "\n";

} elsif ($type =~ /^decode$/i) {
  my $user = get_input(\@ARGV, "string: ");
  print decode_base64($user), "\n";

} elsif ($type =~ /^encode$/i) {
  my $user = get_input(\@ARGV, "string: ");
  print encode_base64($user, ""), "\n";

} elsif ($type =~ /^login$/i) {
  my $user = get_input(\@ARGV, "username: ");
  my $pass = get_input(\@ARGV, "password: ", 1);
  print "Username: ", encode_base64($user, ""), "\n",
        "Password: ", encode_base64($pass, ""), "\n";

} elsif ($type =~ /^cram(-md5)?$/i) {
  try_load("Digest::MD5") || die "Digest::MD5 required for CRAM-MD5\n";
  my $user = get_input(\@ARGV, "username: ");
  my $pass = get_input(\@ARGV, "password: ", 1);
  my $chal = get_input(\@ARGV, "challenge: ");
  if ($chal !~ /^</) {
    chomp($chal = decode_base64($chal));
  }
  my $digest = get_digest($pass, $chal);
  print encode_base64("$user $digest", ""), "\n";

} elsif ($type =~ /^(ntlm|spa|msn)$/i) {
  try_load("Authen::NTLM") || die "Authen::NTLM required for $type\n";
  my $user = get_input(\@ARGV, "username: ");
  my $pass = get_input(\@ARGV, "password: ", 1);
  my $domn = get_input(\@ARGV, "domain: ");
  Authen::NTLM::ntlm_user($user);
  Authen::NTLM::ntlm_password($pass);
  Authen::NTLM::ntlm_domain($domn);
  print "Auth Request: ", Authen::NTLM::ntlm(), "\n";
  my $chal = get_input(\@ARGV, "challenge: ");
  print "Auth Response: ", Authen::NTLM::ntlm($chal), "\n";

} else {
  print STDERR "I don't speak $type\n";
  exit 1;
}

exit 0;

sub get_input {
  my $a = shift; # command line array
  my $s = shift; # prompt string
  my $q = shift; # quiet
  my $r;         # response

  if (scalar(@$a) > 0) {
    $r = shift(@$a);
  } else {
    print $s;
    system('stty', '-echo') if ($q);
    $r = <>;
    system('stty', 'echo') if ($q);
    print "\n" if ($q);
    chomp($r);
  }

  $r = '' if ($r eq '<>');
  return($r);
}

sub get_digest {
  my $secr = shift;
  my $chal = shift;
  my $retr = '';
  my $ipad = chr(0x36);
  my $opad = chr(0x5c);
  my($isec, $osec) = undef;

  if (length($secr) > 64) {
    $secr = Digest::MD5::md5($secr);
  } else {
    $secr .= chr(0) x (64 - length($secr));
  }

  foreach my $char (split(//, $secr)) {
    $isec .= $char ^ $ipad;
    $osec .= $char ^ $opad;
  }

  map { $retr .= sprintf("%02x", ord($_)) }
            split(//,Digest::MD5::md5($osec . Digest::MD5::md5($isec . $chal)));
  return($retr);
}

sub try_load {
  my $mod = shift;

  eval("use $mod");
  return $@ ? 0 : 1;
}

sub ext_usage {
  if ($ARGV[0] =~ /^--help$/i) {
    require Config;
    $ENV{PATH} .= ":" unless $ENV{PATH} eq "";
    $ENV{PATH} = "$ENV{PATH}$Config::Config{'installscript'}";
    exec("perldoc", "-F", "-U", $0) || exit 1;
    # make parser happy
    %Config::Config = ();
  } elsif ($ARGV[0] =~ /^--version$/i) {
    print "$p_name version $p_version\n\n$p_cp\n";
  } else {
    return;
  }

  exit(0);
}
