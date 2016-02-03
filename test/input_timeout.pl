#!/usr/local/bin/perl -w
          eval {
             local $SIG{ALRM} = sub {$timeout = 1};
             alarm (3);
             return <STDIN>;
          };
        alarm (0);
        if ($timeout) {
           print "-ERR timeout! Disconnected\n";
           $timeout = 0;
        }

