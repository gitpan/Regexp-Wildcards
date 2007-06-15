#!perl -T

use Test::More tests => 7;

use Regexp::Wildcards qw/wc2re_unix wc2re_win32/;

ok((not defined wc2re_unix('a,b,c')), 'unix: no commas allowed out of brackets');
ok(wc2re_unix('a\\,b\\\\\\,c') eq 'a\\,b\\\\\\,c', 'unix: no commas allowed out of brackets');

ok(wc2re_win32('a,b\\\\,c') eq '(?:a|b\\\\|c)', 'win32: commas');
ok(wc2re_win32('a\\,b\\\\,c') eq '(?:a\\,b\\\\|c)', 'win32: escaped commas 1');
ok(wc2re_win32('a\\,b\\\\\\,c') eq 'a\\,b\\\\\\,c', 'win32: escaped commas 2');

ok(wc2re_win32(',a,b\\\\,') eq '(?:|a|b\\\\|)', 'win32: commas at begin/end');
ok(wc2re_win32('\\,a,b\\\\\\,') eq '(?:\\,a|b\\\\\\,)', 'win32: escaped commas at begin/end');
