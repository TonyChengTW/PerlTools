#!/usr/bin/perl

$new_pwd='541021';

$enc_old_pwd='ZoEOhcwf0fZW.';
$salt = substr($enc_old_pwd,0,2);
$enc_new_pwd = crypt($new_pwd,$salt);
if ($enc_new_pwd eq $enc_old_pwd) {
    print "right passwd\n";
} else {
#    $enc_new_pwd = crypt($new_pwd,'apol');
#    if ($enc_new_pwd eq $enc_old_pwd) {
#        print "right passwd\n";
#		} else {
		    print "wrong passwd\n";
#	  }
}
