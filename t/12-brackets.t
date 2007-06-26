#!perl -T

use Test::More tests => 27;

use Regexp::Wildcards qw/wc2re_jokers wc2re_sql wc2re_unix wc2re_win32/;

ok(wc2re_jokers('a{b\\\\,c\\\\}d') eq 'a\\{b\\\\\\,c\\\\\\}d', 'wc2re_jokers');

ok(wc2re_sql('a{b\\\\,c\\\\}d') eq 'a\\{b\\\\\\,c\\\\\\}d', 'wc2re_sql');

ok(wc2re_win32('a{b\\\\,c\\\\}d') eq '(?:a\\{b\\\\|c\\\\\\}d)', 'wc2re_win32');

ok(wc2re_unix('{}') eq '(?:)', 'empty brackets');
ok(wc2re_unix('{a}') eq '(?:a)', 'brackets 1');
ok(wc2re_unix('{a,b}') eq '(?:a|b)', 'brackets 2');
ok(wc2re_unix('{a,b,c}') eq '(?:a|b|c)', 'brackets 3');

ok(wc2re_unix('a{b,c}d') eq 'a(?:b|c)d',
   '1 bracketed block');
ok(wc2re_unix('a{b,c}d{e,,f}') eq 'a(?:b|c)d(?:e||f)',
   '2 bracketed blocks');
ok(wc2re_unix('a{b,c}d{e,,f}{g,h,}') eq 'a(?:b|c)d(?:e||f)(?:g|h|)',
   '3 bracketed blocks');

ok(wc2re_unix('{a{b}}') eq '(?:a(?:b))',
   '2 nested bracketed blocks 1');
ok(wc2re_unix('{a,{b},c}') eq '(?:a|(?:b)|c)',
   '2 nested bracketed blocks 2');
ok(wc2re_unix('{a,{b{d}e},c}') eq '(?:a|(?:b(?:d)e)|c)',
   '3 nested bracketed blocks');
ok(wc2re_unix('{a,{b{d{}}e,f,,},c}') eq '(?:a|(?:b(?:d(?:))e|f||)|c)',
   '4 nested bracketed blocks');
ok(wc2re_unix('{a,{b{d{}}e,f,,},c}{,g{{}h,i}}') eq '(?:a|(?:b(?:d(?:))e|f||)|c)(?:|g(?:(?:)h|i))',
   '4+3 nested bracketed blocks');

ok(wc2re_unix('\\{\\\\}') eq '\\{\\\\\\}',
   'escaping brackets');
ok(wc2re_unix('\\{a,b,c\\\\\\}') eq '\\{a\\,b\\,c\\\\\\}',
   'escaping commas 1');
ok(wc2re_unix('\\{a\\\\,b\\,c}') eq '\\{a\\\\\\,b\\,c\\}',
   'escaping commas 2');
ok(wc2re_unix('\\{a\\\\,b\\,c\\}') eq '\\{a\\\\\\,b\\,c\\}',
   'escaping commas 3');
ok(wc2re_unix('\\{a\\\\,b\\,c\\\\}') eq '\\{a\\\\\\,b\\,c\\\\\\}',
   'escaping brackets and commas');

ok(wc2re_unix('{a\\},b\\{,c}') eq '(?:a\\}|b\\{|c)',
   'overlapping brackets');
ok(wc2re_unix('{a\\{b,c}d,e}') eq '(?:a\\{b|c)d\\,e\\}',
   'partial unbalanced catching 1');
ok(wc2re_unix('{a\\{\\\\}b,c\\\\}') eq '(?:a\\{\\\\)b\\,c\\\\\\}',
   'partial unbalanced catching 2');
ok(wc2re_unix('{a{b,c\\}d,e}') eq '\\{a\\{b\\,c\\}d\\,e\\}',
   'no partial unbalanced catching');
ok(wc2re_unix('{a,\\{,\\},b}') eq '(?:a|\\{|\\}|b)',
   'substituting commas 1');
ok(wc2re_unix('{a,\\{d,e,,\\}b,c}') eq '(?:a|\\{d|e||\\}b|c)',
   'substituting commas 2');
ok(wc2re_unix('{a,\\{d,e,,\\}b,c}\\\\{f,g,h,i}') eq '(?:a|\\{d|e||\\}b|c)\\\\(?:f|g|h|i)',
   'handling the rest');
