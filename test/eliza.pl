#!/usr/local/bin/perl
use Chatbot::Eliza;
$| = 1;
my $bot = Chatbot::Eliza->new;
$bot->command_interface();
