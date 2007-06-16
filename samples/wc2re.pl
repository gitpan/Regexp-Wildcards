#!/bin/env perl

use strict;
use warnings;

use Regexp::Wildcards qw/wc2re/;

my $type = (grep $^O eq $_, qw/dos os2 MSWin32 cygwin/) ? 'win32' : 'unix';

print "For this system, type is $type\n";
print $_, ' => ', wc2re($_ => $type), "\n" for @ARGV;
