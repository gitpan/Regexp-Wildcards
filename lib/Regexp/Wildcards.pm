package Regexp::Wildcards;

use strict;
use warnings;

use Text::Balanced qw/extract_bracketed/;

=head1 NAME

Regexp::Wildcards - Converts wildcards expressions to Perl regular expressions.

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    use Regexp::Wildcards qw/wc2re/;

    my $re;
    $re = wc2re 'a{b.,c}*' => 'unix';   # Do it Unix style.
    $re = wc2re 'a.,b*'    => 'win32';  # Do it Windows style.
    $re = wc2re '*{x,y}.'  => 'jokers'; # Process the jokers & escape the rest.

=head1 DESCRIPTION

In many situations, users may want to specify patterns to match but don't need the full power of regexps. Wildcards make one of those sets of simplified rules. This module converts wildcards expressions to Perl regular expressions, so that you can use them for matching. It handles the C<*> and C<?> jokers, as well as Unix bracketed alternatives C<{,}>, and uses the backspace (C<\>) as an escape character. Wrappers are provided to mimic the behaviour of Windows and Unix shells.

=head1 EXPORT

Four functions are exported only on request : C<wc2re>, C<wc2re_unix>, C<wc2re_win32> and C<wc2re_jokers>.

=cut

use base qw/Exporter/;

my %types = (
 'jokers' => \&wc2re_jokers,
 'unix'   => \&wc2re_unix,
 'win32'  => \&wc2re_win32
);

our @EXPORT      = ();
our @EXPORT_OK   = ('wc2re', map { 'wc2re_' . $_ } keys %types);
our @EXPORT_FAIL = qw/extract do_jokers do_commas do_brackets do_bracketed/; 
our %EXPORT_TAGS = ( all => [ @EXPORT_OK ] );

=head1 FUNCTIONS

=head2 C<wc2re_unix>

This function takes as its only argument the wildcard string to process, and returns the corresponding regular expression according to standard Unix wildcard rules. It successively escapes all unprotected regexp special characters that doesn't hold any meaning for wildcards, turns jokers into their regexp equivalents, and changes bracketed blocks into C<(?:|)> alternations. If brackets are unbalanced, it will try to substitute as many of them as possible, and then escape the remaining C<{> and C<}>. Commas outside of any bracket-delimited block will also be escaped.

    # This is a valid brackets expression which is correctly handled.
    print 'ok' if wc2re_unix('{a{b,c}d,e}') eq '(?:a(?:b|c)d|e)';

Unbalanced bracket expressions can always be rescued, but it may change completely its meaning. For example :

    # The first comma is replaced, and the remaining brackets and comma are
    # escaped.
    print 'ok' if wc2re_unix('{a\\{b,c}d,e}') eq '(?:a\\{b|c)d\\,e\\}';

    # All the brackets and commas are escaped.
    print 'ok' if wc2re_unix('{a{b,c\\}d,e}') eq '\\{a\\{b\\,c\\}d\\,e\\}';

=cut

sub wc2re_unix {
 my ($re) = @_;
 return unless defined $re;
 $re =~ s/(?<!\\)((?:\\\\)*[^\w\s?*\\\{\},])/\\$1/g;
 return do_bracketed(do_jokers($re));
}

=head2 C<wc2re_win32>

Similar to the precedent, but for Windows wildcards. Bracketed blocks are no longer handled (which means that brackets will be escaped), but you can provide a comma-separated list of items.

    # All the brackets are escaped, and commas are seen as list delimiters.
    print 'ok' if wc2re_win32('{a{b,c}d,e}') eq '(?:\\{a\\{b|c\\}d|e\\})';

=cut

sub wc2re_win32 {
 my ($wc) = @_;
 return unless defined $wc;
 $wc =~ s/(?<!\\)((?:\\\\)*[^\w\s?*\\,])/\\$1/g;
 my $re = do_jokers($wc);
 if ($re =~ /(?<!\\)(?:\\\\)*,/) { # win32 allows comma-separated lists
  $re = '(?:' . do_commas($re) . ')';
 }
 return $re;
}

=head2 C<wc2re_jokers>

This one only handles the C<?> and C<*> jokers. All other unquoted regexp metacharacters will be escaped.

    # Everything is escaped.
    print 'ok' if wc2re_jokers('{a{b,c}d,e}') eq '\\{a\\{b\\,c\\}d\\,e\\}';

=cut

sub wc2re_jokers {
 my ($wc) = @_;
 $wc =~ s/(?<!\\)((?:\\\\)*[^\w\s?*\\])/\\$1/g;
 return do_jokers($wc);
}

=head2 C<wc2re>

A generic function that wraps around all the different rules. The first argument is the wildcard expression, and the second one is the type of rules to apply, currently either C<unix>, C<win32> or C<jokers>. If the type is undefined, it defaults to C<unix>.

=cut

sub wc2re {
 my ($wc, $type) = @_;
 return unless defined $wc;
 $type ||= 'unix';
 return $types{lc $type}($wc);
}

=head1 DEPENDENCIES

L<Text::Balanced>, which is bundled with perl since version 5.7.3

=head1 SEE ALSO

Some modules provide incomplete alternatives as helper functions :

L<Net::FTPServer> has a method for that. Only jokers are translated, and escaping won't preserve them.

L<File::Find::Match::Util> has a C<wildcar> function that compiles a matcher. Only handles C<*>.

L<Text::Buffer> has the C<convertWildcardToRegex> class method that handles jokers.

=head1 AUTHOR

Vincent Pit, C<< <perl at profvince.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-regexp-wildcards at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Regexp-Wildcards>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Regexp::Wildcards

=head1 COPYRIGHT & LICENSE

Copyright 2007 Vincent Pit, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

sub extract { extract_bracketed shift, '{',  qr/.*?(?:(?<!\\)(?:\\\\)*)(?={)/; }

sub do_jokers {
 local $_ = shift;
 # escape an odd number of \ that doesn't protect a regexp/wildcard special char
 s/(?<!\\)((?:\\\\)*\\(?:[\w\s]|$))/\\$1/g;
 # substitute ? preceded by an even number of \
 s/(?<!\\)((?:\\\\)*)\?/$1./g;
 # substitute * preceded by an even number of \
 s/(?<!\\)((?:\\\\)*)\*+/$1.*/g;
 return $_;
}

sub do_commas {
 local $_ = shift;
 # substitute , preceded by an even number of \
 s/(?<!\\)((?:\\\\)*),/$1|/g;
 return $_;
}

sub do_brackets {
 my $rest = shift;
 substr $rest, 0, 1, '';
 chop $rest;
 my ($re, $bracket, $prefix) = ('');
 while (($bracket, $rest, $prefix) = extract $rest and $bracket) {
  $re .= do_commas($prefix) . do_brackets($bracket);
 }
 $re .= do_commas($rest);
 return '(?:' . $re . ')';
}

sub do_bracketed {
 my $rest = shift;
 my ($re, $bracket, $prefix) = ('');
 while (($bracket, $rest, $prefix) = extract $rest and $bracket) {
  $re .= $prefix . do_brackets($bracket);
 }
 $re .= $rest;
 $re =~ s/(?<!\\)((?:\\\\)*[\{\},])/\\$1/g;
 return $re;
}

1; # End of Regexp::Wildcards
