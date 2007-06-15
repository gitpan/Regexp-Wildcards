#!perl -T

use Test::More tests => 28;

use Regexp::Wildcards qw/wc2re_jokers wc2re_unix wc2re_win32/;

ok(wc2re_jokers('a{b\\\\,c\\\\}d') eq 'a\\{b\\\\\\,c\\\\\\}d');

ok(wc2re_win32('a{b\\\\,c\\\\}d') eq '(?:a\\{b\\\\|c\\\\\\}d)');

ok(wc2re_unix('{}') eq '(?:)');
ok(wc2re_unix('{a}') eq '(?:a)');
ok(wc2re_unix('{a,b}') eq '(?:a|b)');
ok(wc2re_unix('{a,b,c}') eq '(?:a|b|c)');

ok(wc2re_unix('a{b,c}d') eq 'a(?:b|c)d');
ok(wc2re_unix('a{b,c}d{e,,f}') eq 'a(?:b|c)d(?:e||f)');
ok(wc2re_unix('a{b,c}d{e,,f}{g,h,}') eq 'a(?:b|c)d(?:e||f)(?:g|h|)');

ok(wc2re_unix('{a{b}}') eq '(?:a(?:b))');
ok(wc2re_unix('{a,{b},c}') eq '(?:a|(?:b)|c)');
ok(wc2re_unix('{a,{b{d}e},c}') eq '(?:a|(?:b(?:d)e)|c)');
ok(wc2re_unix('{a,{b{d{}}e,f,,},c}') eq '(?:a|(?:b(?:d(?:))e|f||)|c)');
ok(wc2re_unix('{a,{b{d{}}e,f,,},c}{,g{{}h,i}}') eq '(?:a|(?:b(?:d(?:))e|f||)|c)(?:|g(?:(?:)h|i))');

ok(wc2re_unix('\\{\\\\}') eq '\\{\\\\\\}');
ok((not defined wc2re_unix('\\{a,b,c\\\\\\}')));
ok(wc2re_unix('\\{a\\\\\\,b\\,c}') eq '\\{a\\\\\\,b\\,c\\}');
ok(wc2re_unix('\\{a\\\\\\,b\\,c\\}') eq '\\{a\\\\\\,b\\,c\\}');
ok(wc2re_unix('\\{a\\\\\\,b\\,c\\\\}') eq '\\{a\\\\\\,b\\,c\\\\\\}');

ok(wc2re_unix('{a\\},b\\{,c}') eq '(?:a\\}|b\\{|c)');
ok((not defined wc2re_unix('{a,\\{}b,c}')));
ok((not defined wc2re_unix('{a\\{}b,c}')));
ok(wc2re_unix('{a\\{b,c}d\\,e}') eq '(?:a\\{b|c)d\\,e\\}');
ok(wc2re_unix('{a{b\\,c\\}d\\,e}') eq '\\{a\\{b\\,c\\}d\\,e\\}');
ok(wc2re_unix('{a\\{\\\\}b\\,c\\\\}') eq '(?:a\\{\\\\)b\\,c\\\\\\}');
ok(wc2re_unix('{a,\\{\\}b,c}') eq '(?:a|\\{\\}b|c)');
ok(wc2re_unix('{a,\\{d,e,,\\}b,c}') eq '(?:a|\\{d|e||\\}b|c)');
ok(wc2re_unix('{a,\\{d,e,,\\}b,c}\\\\{f,g,h,i}') eq '(?:a|\\{d|e||\\}b|c)\\\\(?:f|g|h|i)');
