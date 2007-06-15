#!perl -T

use Test::More tests => 4;

require Regexp::Wildcards;

for (qw/wc2re_jokers wc2re_unix wc2re_win32 wc2re/) {
 eval { Regexp::Wildcards->import($_) };
 ok(!$@, 'import ' . $_);
}
