#!/usr/local/bin/perl
#  ----------------------------------
#   Writer  : Mico Cheng
#   Version : 2004100101
#   Use for :
#   Host : x
#  ----------------------------------
use DBI;

## ---------------- Variables -----------------------
$domain_file = 'domain.list';
$user_file = 'user.list';
$administrator_file = 'admin.list';

## --------------- ezml --------------------------
$ezml_ip = '203.79.224.60';
$ezml_account = 'root';
$ezml_pwd = 'Au06.wj$';
$ezml_name = 'ezmail';

#-------------------------------------------------------------
# Open EZML
$dbh_ezml=DBI->connect("DBI:mysql:$ezml_name;host=$ezml_ip", $ezml_account,$ezml_pwd) or die "$!\n";

# Open export files
open DOMAIN_LIST,">$domain_file" or die "can't open:$!\n";
open USER_LIST,">$user_file" or die "can't open:$!\n";
open ADMIN_LIST,">$administrator_file" or die "can't open:$!\n";

# Domain List (Domain,Company Name,Domain quota,Expire time)
$sqlstmt=sprintf("SELECT name,memo,mailquota FROM passwd WHERE passwd!='brucelaistop' AND name!='hiway.net.tw'");
$sth=$dbh_ezml->prepare($sqlstmt);
$sth->execute();

while (($domain_name,$company_name,$domain_quota)=($sth->fetchrow_array)[0,1,2]) {
    printf DOMAIN "$domain_name,$company_name,$domain_quota\n";
}
