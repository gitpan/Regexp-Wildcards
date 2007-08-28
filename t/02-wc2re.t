#!perl -T

use strict;
use warnings;

use Test::More tests => 10;

use Regexp::Wildcards qw/wc2re wc2re_win32/;

for my $O (qw/win32 dos os2 cygwin/, 'MSWin32') {
 for ('a{b,c}*', 'a?{b\\{,\\}c}') {
  ok(wc2re($_, $O) eq wc2re_win32($_), $_ . ' (' . $O . ')');
 }
}
