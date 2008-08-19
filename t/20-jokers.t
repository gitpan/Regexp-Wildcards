#!perl -T

use strict;
use warnings;

use Test::More tests => 2 * (4 + 2 + 7 + 8 + 6 + 2) * 3;

use Regexp::Wildcards;

sub try {
 my ($rw, $s, $x, $y) = @_;
 $y = $x unless defined $y;
 my $t = $rw->{type};
 is($rw->convert('ab' . $x),      'ab' . $y,      $s . ' (begin) ['.$t.']');
 is($rw->convert('a' . $x . 'b'), 'a' . $y . 'b', $s . ' (middle) ['.$t.']');
 is($rw->convert($x . 'ab'),      $y . 'ab',      $s . ' (end) ['.$t.']');
}

sub alltests {
 my ($t, $one, $any) = @_;

 my $rw = Regexp::Wildcards->new;
 $rw->type($t);

 # Simple

 try $rw, "simple $any", $any, '.*';
 try $rw, "simple $one", $one, '.';

 is($rw->convert($one.$any.'ab', $t), '..*ab',
    "simple $one and $any (begin) [$t]");
 is($rw->convert($one.'a'.$any.'b', $t), '.a.*b',
    "simple $one and $any (middle) [$t]");
 is($rw->convert($one.'ab'.$any, $t), '.ab.*',
    "simple $one and $any (end) [$t]");

 is($rw->convert($any.'ab'.$one, $t), '.*ab.',
    "simple $any and $one (begin) [$t]");
 is($rw->convert('a'.$any.'b'.$one, $t), 'a.*b.',
    "simple $any and $one (middle) [$t]");
 is($rw->convert('ab'.$any.$one, $t), 'ab.*.',
    "simple $any and $one (end) [$t]");

 # Multiple

 try $rw, "multiple $any", $any x 2, '.*';
 try $rw, "multiple $one", $one x 2, '..';

 # Captures

 $rw->capture('single');
 try $rw, "multiple capturing $one", $one.$one.'\\'.$one.$one,
                                    '(.)(.)\\'.$one.'(.)';

 $rw->capture(add => [ qw/any greedy/ ]);
 try $rw, "multiple capturing $any (greedy)", $any.$any.'\\'.$any.$any,
                                              '(.*)\\'.$any.'(.*)';
 my $wc = $any.$any.$one.$one.'\\'.$one.$one.'\\'.$any.$any;
 try $rw, "multiple capturing $any (greedy) and capturing $one",
          $wc, '(.*)(.)(.)\\'.$one.'(.)\\'.$any.'(.*)';

 $rw->capture(set => [ qw/any greedy/ ]);
 try $rw, "multiple capturing $any (greedy) and non-capturing $one",
          $wc, '(.*)..\\'.$one.'.\\'.$any.'(.*)';

 $rw->capture(rem => 'greedy');
 try $rw, "multiple capturing $any (non-greedy)", $any.$any.'\\'.$any.$any,
                                                 '(.*?)\\'.$any.'(.*?)';
 try $rw, "multiple capturing $any (non-greedy) and non-capturing $one",
          $wc, '(.*?)..\\'.$one.'.\\'.$any.'(.*?)';

 $rw->capture({ single => 1, any => 1 });
 try $rw, "multiple capturing $any (non-greedy) and capturing $one",
          $wc, '(.*?)(.)(.)\\'.$one.'(.)\\'.$any.'(.*?)';

 $rw->capture();

 # Escaping

 try $rw, "escaping $any", '\\'.$any;
 try $rw, "escaping $any before intermediate newline", '\\'.$any ."\n\\".$any;
 try $rw, "escaping $one", '\\'.$one;
 try $rw, "escaping $one before intermediate newline", '\\'.$one ."\n\\".$one;
 try $rw, "escaping \\\\\\$any", '\\\\\\'.$any;
 try $rw, "escaping \\\\\\$one", '\\\\\\'.$one;
 try $rw, "not escaping \\\\$any", '\\\\'.$any, '\\\\.*';
 try $rw, "not escaping \\\\$one", '\\\\'.$one, '\\\\.';

 # Escaping escapes

 try $rw, 'escaping \\', '\\', '\\\\';
 try $rw, 'not escaping \\', '\\\\', '\\\\';
 try $rw, 'escaping \\ before intermediate newline', "\\\n\\", "\\\\\n\\\\";
 try $rw, 'not escaping \\ before intermediate newline', "\\\\\n\\\\", "\\\\\n\\\\";
 try $rw, 'escaping regex characters', '[]', '\\[\\]';
 try $rw, 'not escaping escaped regex characters', '\\\\\\[\\]';

 # Mixed

 try $rw, "mixed $any and \\$any", $any.'\\'.$any.$any, '.*\\'.$any.'.*';
 try $rw, "mixed $one and \\$one", $one.'\\'.$one.$one, '.\\'.$one.'.';
}

alltests 'jokers', '?', '*';
alltests 'sql',    '_', '%';
