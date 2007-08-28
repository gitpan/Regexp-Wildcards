#!perl -T

use strict;
use warnings;

use Test::More tests => 8;

use Regexp::Wildcards qw/wc2re_unix wc2re_win32/;

ok(wc2re_unix('a,b,c') eq 'a\\,b\\,c', 'unix: commas outside of brackets 1');
ok(wc2re_unix('a\\,b\\\\\\,c') eq 'a\\,b\\\\\\,c',
   'unix: commas outside of brackets 2');
ok(wc2re_unix(',a,b,c\\\\,') eq '\\,a\\,b\\,c\\\\\\,',
   'unix: commas outside of brackets at begin/ed');

ok(wc2re_win32('a,b\\\\,c') eq '(?:a|b\\\\|c)', 'win32: commas');
ok(wc2re_win32('a\\,b\\\\,c') eq '(?:a\\,b\\\\|c)', 'win32: escaped commas 1');
ok(wc2re_win32('a\\,b\\\\\\,c') eq 'a\\,b\\\\\\,c', 'win32: escaped commas 2');

ok(wc2re_win32(',a,b\\\\,') eq '(?:|a|b\\\\|)', 'win32: commas at begin/end');
ok(wc2re_win32('\\,a,b\\\\\\,') eq '(?:\\,a|b\\\\\\,)',
   'win32: escaped commas at begin/end');
