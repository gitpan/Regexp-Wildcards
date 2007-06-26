package Regexp::Wildcards;

use strict;
use warnings;

use Text::Balanced qw/extract_bracketed/;

=head1 NAME

Regexp::Wildcards - Converts wildcard expressions to Perl regular expressions.

=head1 VERSION

Version 0.06

=cut

our $VERSION = '0.06';

=head1 SYNOPSIS

    use Regexp::Wildcards qw/wc2re/;

    my $re;
    $re = wc2re 'a{b?,c}*' => 'unix';   # Do it Unix style.
    $re = wc2re 'a?,b*'    => 'win32';  # Do it Windows style.
    $re = wc2re '*{x,y}?'  => 'jokers'; # Process the jokers & escape the rest.
    $re = wc2re '%a_c%'    => 'sql';    # Turn SQL wildcards into regexps.

=head1 DESCRIPTION

In many situations, users may want to specify patterns to match but don't need the full power of regexps. Wildcards make one of those sets of simplified rules. This module converts wildcard expressions to Perl regular expressions, so that you can use them for matching. It handles the C<*> and C<?> shell jokers, as well as Unix bracketed alternatives C<{,}>, but also C<%> and C<_> SQL wildcards. Backspace (C<\>) is used as an escape character. Wrappers are provided to mimic the behaviour of Windows and Unix shells.

=head1 VARIABLES

These variables control if the wildcards jokers and brackets must capture their match. They can be globally set by writing in your program

    $Regexp::Wildcards::CaptureSingle = 1;
    # From then, "exactly one" wildcards are capturing

or can be locally specified via C<local>

    {
     local $Regexp::Wildcards::CaptureSingle = 1;
     # In this block, "exactly one" wildcards are capturing.
     ...
    }
    # Back to the situation from before the block

This section describes also how those elements are translated by the L<functions|/FUNCTIONS>.

=head2 C<$CaptureSingle>

When this variable is true, each occurence of unescaped I<"exactly one"> wildcards (i.e. C<?> jokers or C<_> for SQL wildcards) are made capturing in the resulting regexp (they are be replaced by C<(.)>). Otherwise, they are just replaced by C<.>. Default is the latter.

    For jokers :
    'a???b\\??' is translated to 'a(.)(.)(.)b\\?(.)' if $CaptureSingle is true
                                 'a...b\\?.'         otherwise (default)

    For SQL wildcards :
    'a___b\\__' is translated to 'a(.)(.)(.)b\\_(.)' if $CaptureSingle is true
                                 'a...b\\_.'         otherwise (default)

=cut

our $CaptureSingle = 0;

sub capture_single {
 return $CaptureSingle ? '(.)'
                       : '.';
}

=head2 C<$CaptureAny>

By default this variable is false, and successions of unescaped I<"any"> wildcards (i.e. C<*> jokers or C<%> for SQL wildcards) are replaced by B<one> single C<.*>. When it evalutes to true, those sequences of I<"any"> wildcards are made into B<one> capture, which is greedy (C<(.*)>) for C<$CaptureAny E<gt> 0> and otherwise non-greedy (C<(.*?)>).

    For jokers :
    'a***b\\**' is translated to 'a.*b\\*.*'       if $CaptureAny is false (default)
                                 'a(.*)b\\*(.*)'   if $CaptureAny > 0
                                 'a(.*?)b\\*(.*?)' otherwise

    For SQL wildcards :
    'a%%%b\\%%' is translated to 'a.*b\\%.*'       if $CaptureAny is false (default)
                                 'a(.*)b\\%(.*)'   if $CaptureAny > 0
                                 'a(.*?)b\\%(.*?)' otherwise

=cut

our $CaptureAny = 0;

sub capture_any {
 return $CaptureAny ? (($CaptureAny > 0) ? '(.*)'
                                         : '(.*?)')
                    : '.*';
}

=head2 C<$CaptureBrackets>

If this variable is set to true, valid brackets constructs are made into C<( | )> captures, and otherwise they are replaced by non-capturing alternations (C<(?: | >)), which is the default.

    'a{b\\},\\{c}' is translated to 'a(b\\}|\\{c)'   if $CaptureBrackets is true
                                    'a(?:b\\}|\\{c)' otherwise (default)

=cut

our $CaptureBrackets = 0;

sub capture_brackets {
 return $CaptureBrackets ? '('
                         : '(?:';
}

=head1 FUNCTIONS

=head2 C<wc2re_jokers>

This function takes as its only argument the wildcard string to process, and returns the corresponding regular expression where the jokers C<?> (I<"exactly one">) and C<*> (I<"any">) have been translated into their regexp equivalents (see L</VARIABLES> for more details). All other unprotected regexp metacharacters are escaped.

    # Everything is escaped.
    print 'ok' if wc2re_jokers('{a{b,c}d,e}') eq '\\{a\\{b\\,c\\}d\\,e\\}';

=cut

sub wc2re_jokers {
 my ($wc) = @_;
 $wc =~ s/(?<!\\)((?:\\\\)*[^\w\s?*\\])/\\$1/g;
 return do_jokers($wc);
}

=head2 C<wc2re_sql>

Similar to the precedent, but for the SQL wildcards C<_> (I<"exactly one">) and C<%> (I<"any">). All other unprotected regexp metacharacters are escaped.
 
=cut
  
sub wc2re_sql {
 my ($wc) = @_;
 $wc =~ s/(?<!\\)((?:\\\\)*[^\w\s%\\])/\\$1/g;
 return do_sql($wc);
}

=head2 C<wc2re_unix>

This function conforms to standard Unix shell wildcard rules. It successively escapes all unprotected regexp special characters that doesn't hold any meaning for wildcards, turns C<?> and C<*> jokers into their regexp equivalents (see L</wc2re_jokers>), and changes bracketed blocks into (possibly capturing) alternations as described in L</VARIABLES>. If brackets are unbalanced, it tries to substitute as many of them as possible, and then escape the remaining C<{> and C<}>. Commas outside of any bracket-delimited block are also escaped.

    # This is a valid bracket expression, and is completely translated.
    print 'ok' if wc2re_unix('{a{b,c}d,e}') eq '(?:a(?:b|c)d|e)';

The function handles unbalanced bracket expressions, by escaping everything it can't recognize. For example :

    # The first comma is replaced, and the remaining brackets and comma are escaped.
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

This one works just like the one before, but for Windows wildcards. Bracketed blocks are no longer handled (which means that brackets are escaped), but you can provide a comma-separated list of items.

    # All the brackets are escaped, and commas are seen as list delimiters.
    print 'ok' if wc2re_win32('{a{b,c}d,e}') eq '(?:\\{a\\{b|c\\}d|e\\})';

=cut

sub wc2re_win32 {
 my ($wc) = @_;
 return unless defined $wc;
 $wc =~ s/(?<!\\)((?:\\\\)*[^\w\s?*\\,])/\\$1/g;
 my $re = do_jokers($wc);
 if ($re =~ /(?<!\\)(?:\\\\)*,/) { # win32 allows comma-separated lists
  $re = capture_brackets . do_commas($re) . ')';
 }
 return $re;
}

=head2 C<wc2re>

A generic function that wraps around all the different rules. The first argument is the wildcard expression, and the second one is the type of rules to apply which can be :

=over 4

=item C<'unix'>, C<'win32'>, C<'jokers'>, C<'sql'>

For one of those raw rule names, C<wc2re> simply maps to C<wc2re_unix>, C<wc2re_win32>, C<wc2re_jokers> and C<wc2re_sql> respectively.

=item C<$^O>

If you supply the Perl operating system name, the call is deferred to C<wc2re_win32> for C< $^O> equal to C<'dos'>, C<'os2'>, C<'MSWin32'> or C<'cygwin'>, and to C<wc2re_unix> in all the other cases.

=back

If the type is undefined or not supported, it defaults to C<'unix'>.

     # Wraps to wc2re_jokers ($re eq 'a\\{b\\,c\\}.*').
     $re = wc2re 'a{b,c}*' => 'jokers';

     # Wraps to wc2re_win32 ($re eq '(?:a\\{b|c\\}.*)')
     #       or wc2re_unix  ($re eq 'a(?:b|c).*')       depending on $^O.
     $re = wc2re 'a{b,c}*' => $^O;

=cut

my %types = (
 'jokers'    => \&wc2re_jokers,
 'sql'       => \&wc2re_sql,
 'unix'      => \&wc2re_unix,
 map { lc $_ => \&wc2re_win32 } qw/win32 dos os2 MSWin32 cygwin/
);

sub wc2re {
 my ($wc, $type) = @_;
 return unless defined $wc;
 $type = $type ? lc $type : 'unix';
 $type = 'unix' unless exists $types{$type};
 return $types{$type}($wc);
}

=head1 EXPORT

These five functions are exported only on request : C<wc2re>, C<wc2re_unix>, C<wc2re_win32>, C<wc2re_jokers> and C<wc2re_sql>. The variables are not exported.

=cut

use base qw/Exporter/;

our @EXPORT      = ();
our @EXPORT_OK   = ('wc2re', map { 'wc2re_'.$_ } keys %types);
our @EXPORT_FAIL = qw/extract/,
                   (map { 'do_'.$_ } qw/jokers sql commas brackets bracketed/),
                   (map { 'capture_'.$_ } qw/single any brackets/);
our %EXPORT_TAGS = ( all => [ @EXPORT_OK ] );

=head1 DEPENDENCIES

L<Text::Balanced>, which is bundled with perl since version 5.7.3

=head1 CAVEATS

This module does not implement the strange behaviours of Windows shell that result from the special handling of the three last characters (for the file extension). For example, Windows XP shell matches C<*a> like C<.*a>, C<*a?> like C<.*a.?>, C<*a??> like C<.*a.{0,2}> and so on.

=head1 SEE ALSO

Some modules provide incomplete alternatives as helper functions :

L<Net::FTPServer> has a method for that. Only jokers are translated, and escaping won't preserve them.

L<File::Find::Match::Util> has a C<wildcard> function that compiles a matcher. It only handles C<*>.

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

sub extract { extract_bracketed shift, '{',  qr/.*?(?<!\\)(?:\\\\)*(?={)/; }

sub do_jokers {
 local $_ = shift;
 # escape an odd number of \ that doesn't protect a regexp/wildcard special char
 s/(?<!\\)((?:\\\\)*\\(?:[\w\s]|$))/\\$1/g;
 # substitute ? preceded by an even number of \
 my $s = capture_single;
 s/(?<!\\)((?:\\\\)*)\?/$1$s/g;
 # substitute * preceded by an even number of \
 $s = capture_any;
 s/(?<!\\)((?:\\\\)*)\*+/$1$s/g;
 return $_;
}

sub do_sql {
 local $_ = shift;
 # escape an odd number of \ that doesn't protect a regexp/wildcard special char
 s/(?<!\\)((?:\\\\)*\\(?:[^\W_]|\s|$))/\\$1/g;
 # substitute _ preceded by an even number of \
 my $s = capture_single;
 s/(?<!\\)((?:\\\\)*)_/$1$s/g;
 # substitute * preceded by an even number of \
 $s = capture_any;
 s/(?<!\\)((?:\\\\)*)%+/$1$s/g;
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
 return capture_brackets . $re . ')';
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
