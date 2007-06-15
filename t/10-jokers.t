#!perl -T

use Test::More tests => 3 * (4 + 2 + 9 + 2) * 3;

use Regexp::Wildcards qw/wc2re/;

sub try {
 my ($t, $s, $x, $y) = @_;
 $y = $x unless defined $y;
 ok(wc2re('ab' . $x,      $t) eq 'ab' . $y,      $s . ' (beginning)');
 ok(wc2re('a' . $x . 'b', $t) eq 'a' . $y . 'b', $s . ' (middle)');
 ok(wc2re($x . 'ab',      $t) eq $y . 'ab',      $s . ' (end)');
}

for my $t (qw/unix win32 jokers/) {
 # Simple

 try $t, 'simple *', '*', '.*';
 try $t, 'simple ?', '?', '.';

 ok(wc2re('?*ab', $t) eq '..*ab', 'simple ? and * (beginning)');
 ok(wc2re('?a*b', $t) eq '.a.*b', 'simple ? and * (middle)');
 ok(wc2re('?ab*', $t) eq '.ab.*', 'simple ? and * (end)');

 ok(wc2re('*ab?', $t) eq '.*ab.', 'simple * and ? (beginning)');
 ok(wc2re('a*b?', $t) eq 'a.*b.', 'simple * and ? (middle)');
 ok(wc2re('ab*?', $t) eq 'ab.*.', 'simple * and ? (end)');

 # Multiple

 try $t, 'multiple *', '**', '.*';
 try $t, 'multiple ?', '??', '..';

 # Escaping

 try $t, 'escaping *', '\\*';
 try $t, 'escaping *', '\\?';
 try $t, 'escaping \\\\\\*', '\\\\\\*';
 try $t, 'escaping \\\\\\?', '\\\\\\?';

 try $t, 'not escaping \\\\*', '\\\\*', '\\\\.*';
 try $t, 'not escaping \\\\?', '\\\\?', '\\\\.';

 try $t, 'escaping \\', '\\', '\\\\';
 try $t, 'escaping regex characters', '[]', '\\[\\]';
 try $t, 'not escaping escaped regex characters', '\\\\\\[\\]';

 # Mixed

 try $t, 'mixed * and \\*', '*\\**', '.*\\*.*';
 try $t, 'mixed ? and \\?', '?\\??', '.\\?.';
}
