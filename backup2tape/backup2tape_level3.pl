#!/usr/local/bin/perl
#---------------------------------------
# Writer:  Miko Cheng
# Version: 20041122
# use for: backup aptg Data Level III to Tape
# host: 10.0.2.47 ----FTP---> 10.0.3.74
#---------------------------------------
use Net::FTP;

use constant FTP_HOST => '10.0.3.74';
use constant FTP_PORT => '21';
use constant FTP_DIR_APTG => '/f:/level_c/miko/aptg_mail';
use constant FTP_USER => 'miko';
use constant FTP_PASSWD => 'miko8489';

$backup_log = '/mico/backup2tape/backup2tape_level1.log';
open (STDOUT,">>$backup_log");
open (STDERR,">&STDOUT");

$| = 1;
### get date & time
$timestamp = time;
($sec, $min, $hour, $day, $mon) = (localtime $timestamp)[0, 1, 2, 3, 4];
$date = sprintf("%02d/%02d %02d:%02d:%02d", $mon+1, $day, $hour, $min, $sec);

print "Info: $date starting backup ====================================\n";

### create ftp object
@backup_list = `/usr/local/bin/find /backup/db -type f -mtime -1`;

$ftp = Net::FTP->new(FTP_HOST) or die "Err0: $date Can't connect to FTP_HOST:$@\n";
$ftp->login(FTP_USER,FTP_PASSWD) or die "Err1: $date $ftp->message\n";
$ftp->cwd(FTP_DIR_APTG) or die "Err2: $date $ftp->message:$!\n";
$ftp->binary or die "Err3: $date $ftp->message\n";

foreach (@backup_list) {
	  chomp;
		print "Info: uploading $_.....";
    $ftp->put($_) or die "Err4: $date $ftp->message\n";
		$parsing_filename = $_;
		($old_filename) = $parsing_filename =~ /^.*\/(.*)$/;
		($new_name,$new_type) = $parsing_filename =~ /^.*\/(.*)-200[0-9][0-9]*(\..*$)/;
		$new_filename = $new_name.$new_type;
		$ftp->rename($old_filename,$new_filename);
		print "OK!\n";
}
#----------------------------------------------------------------------------
$ftp->quit;
print "Info: Done!====================================\n";
