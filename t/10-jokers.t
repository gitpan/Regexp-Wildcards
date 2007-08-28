#!perl -T

use strict;
use warnings;

use Test::More tests => 4 * (4 + 2 + 7 + 9 + 2) * 3;

use Regexp::Wildcards qw/wc2re/;

sub try {
 my ($t, $s, $x, $y) = @_;
 $y = $x unless defined $y;
 ok(wc2re('ab' . $x,      $t) eq 'ab' . $y,      $s . ' (begin) ['.$t.']');
 ok(wc2re('a' . $x . 'b', $t) eq 'a' . $y . 'b', $s . ' (middle) ['.$t.']');
 ok(wc2re($x . 'ab',      $t) eq $y . 'ab',      $s . ' (end) ['.$t.']');
}

sub alltests {
 my ($t, $one, $any) = @_;

 # Simple

 try $t, "simple $any", $any, '.*';
 try $t, "simple $one", $one, '.';

 ok(wc2re($one.$any.'ab', $t)    eq '..*ab',
    "simple $one and $any (begin) [$t]");
 ok(wc2re($one.'a'.$any.'b', $t) eq '.a.*b',
    "simple $one and $any (middle) [$t]");
 ok(wc2re($one.'ab'.$any, $t)    eq '.ab.*',
    "simple $one and $any (end) [$t]");

 ok(wc2re($any.'ab'.$one, $t)    eq '.*ab.',
    "simple $any and $one (begin) [$t]");
 ok(wc2re('a'.$any.'b'.$one, $t) eq 'a.*b.',
    "simple $any and $one (middle) [$t]");
 ok(wc2re('ab'.$any.$one, $t)    eq 'ab.*.',
    "simple $any and $one (end) [$t]");

 # Multiple

 try $t, "multiple $any", $any x 2, '.*';
 try $t, "multiple $one", $one x 2, '..';

 # Variables

 {
  local $Regexp::Wildcards::CaptureSingle = 1;
  try $t, "multiple capturing $one", $one.$one.'\\'.$one.$one,
                                     '(.)(.)\\'.$one.'(.)';

  local $Regexp::Wildcards::CaptureAny = 1;
  try $t, "multiple capturing $any (greedy)", $any.$any.'\\'.$any.$any,
                                              '(.*)\\'.$any.'(.*)';
  my $wc = $any.$any.$one.$one.'\\'.$one.$one.'\\'.$any.$any;
  try $t, "multiple capturing $any (greedy) and capturing $one",
          $wc, '(.*)(.)(.)\\'.$one.'(.)\\'.$any.'(.*)';

  $Regexp::Wildcards::CaptureSingle = 0;
  try $t, "multiple capturing $any (greedy) and non-capturing $one",
          $wc, '(.*)..\\'.$one.'.\\'.$any.'(.*)';

  $Regexp::Wildcards::CaptureAny = -1;
  try $t, "multiple capturing $any (non-greedy)", $any.$any.'\\'.$any.$any,
                                                  '(.*?)\\'.$any.'(.*?)';
  try $t, "multiple capturing $any (non-greedy) and non-capturing $one",
          $wc, '(.*?)..\\'.$one.'.\\'.$any.'(.*?)';

  $Regexp::Wildcards::CaptureSingle = 1;
  try $t, "multiple capturing $any (non-greedy) and capturing $one",
          $wc, '(.*?)(.)(.)\\'.$one.'(.)\\'.$any.'(.*?)';
 }

 # Escaping

 try $t, "escaping $any", '\\'.$any;
 try $t, "escaping $one", '\\'.$one;
 try $t, "escaping \\\\\\$any", '\\\\\\'.$any;
 try $t, "escaping \\\\\\$one", '\\\\\\'.$one;

 try $t, "not escaping \\\\$any", '\\\\'.$any, '\\\\.*';
 try $t, "not escaping \\\\$one", '\\\\'.$one, '\\\\.';

 try $t, 'escaping \\', '\\', '\\\\';
 try $t, 'escaping regex characters', '[]', '\\[\\]';
 try $t, 'not escaping escaped regex characters', '\\\\\\[\\]';

 # Mixed

 try $t, "mixed $any and \\$any", $any.'\\'.$any.$any, '.*\\'.$any.'.*';
 try $t, "mixed $one and \\$one", $one.'\\'.$one.$one, '.\\'.$one.'.';
}

alltests $_,    '?', '*' for qw/jokers unix win32/;
alltests 'sql', '_', '%';
