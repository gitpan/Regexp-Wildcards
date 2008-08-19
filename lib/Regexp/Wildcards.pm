package Regexp::Wildcards;

use strict;
use warnings;

use Carp qw/croak/;
use Text::Balanced qw/extract_bracketed/;

=head1 NAME

Regexp::Wildcards - Converts wildcard expressions to Perl regular expressions.

=head1 VERSION

Version 1.01

=cut

use vars qw/$VERSION/;
BEGIN {
 $VERSION = '1.01';
}

=head1 SYNOPSIS

    use Regexp::Wildcards;

    my $rw = Regexp::Wildcards->new(type => 'unix');

    my $re;
    $re = $rw->convert('a{b?,c}*');          # Do it Unix shell style.
    $re = $rw->convert('a?,b*',   'win32');  # Do it Windows shell style.
    $re = $rw->convert('*{x,y}?', 'jokers'); # Process the jokers and escape the rest.
    $re = $rw->convert('%a_c%',   'sql');    # Turn SQL wildcards into regexps.

    $rw = Regexp::Wildcards->new(
     do      => [ qw/jokers brackets/ ], # Do jokers and brackets.
     capture => [ qw/any greedy/ ],      # Capture *'s greedily.
    );

    $rw->do(add => 'groups');            # Don't escape groups.
    $rw->capture(rem => [ qw/greedy/ ]); # Actually we want non-greedy matches.
    $re = $rw->convert('*a{,(b)?}?c*');  # '(.*?)a(?:|(b).).c(.*?)'
    $rw->capture();                      # No more captures.

=head1 DESCRIPTION

In many situations, users may want to specify patterns to match but don't need the full power of regexps. Wildcards make one of those sets of simplified rules. This module converts wildcard expressions to Perl regular expressions, so that you can use them for matching.

It handles the C<*> and C<?> jokers, as well as Unix bracketed alternatives C<{,}>, but also C<%> and C<_> SQL wildcards. It can also keep original C<(...)> groups. Backspace (C<\>) is used as an escape character.

Typesets that mimic the behaviour of Windows and Unix shells are also provided.

=head1 METHODS

=cut

sub _check_self {
 croak 'First argument isn\'t a valid ' . __PACKAGE__ . ' object'
  unless ref $_[0] and $_[0]->isa(__PACKAGE__);
}

my %types = (
 jokers   => [ qw/jokers/ ],
 sql      => [ qw/sql/ ],
 commas   => [ qw/commas/ ],
 brackets => [ qw/brackets/ ],
 unix     => [ qw/jokers brackets/ ],
 win32    => [ qw/jokers commas/ ],
);
$types{$_} = $types{win32} for qw/dos os2 MSWin32 cygwin/;

my %escapes = (
 jokers   => '?*',
 sql      => '_%',
 commas   => ',',
 brackets => '{},',
 groups   => '()',
);

my %captures = (
 single   => sub { $_[1] ? '(.)' : '.' },
 any      => sub { $_[1] ? ($_[0]->{greedy} ? '(.*)'
                                            : '(.*?)')
                         : '.*' },
 brackets => sub { $_[1] ? '(' : '(?:'; },
 greedy   => undef
);

sub _validate {
 my $self  = shift;
 _check_self $self;
 my $valid = shift;
 my $old   = shift;
 $old = { } unless defined $old;
 my $c;
 if (@_ <= 1) {
  $c = { set => $_[0] };
 } elsif (@_ % 2) {
  croak 'Arguments must be passed as an unique scalar or as key => value pairs';
 } else {
  my %args = @_;
  $c = { map { (exists $args{$_}) ? ($_ => $args{$_}) : () } qw/set add rem/ };
 }
 for (qw/set add rem/) {
  my $v = $c->{$_};
  next unless defined $v;
  my $cb = {
   ''      => sub { +{ ($_[0] => 1) x (exists $valid->{$_[0]}) } },
   'ARRAY' => sub { +{ map { ($_ => 1) x (exists $valid->{$_}) } @{$_[0]} } },
   'HASH'  => sub { +{ map { ($_ => $_[0]->{$_}) x (exists $valid->{$_}) }
                        keys %{$_[0]} } }
  }->{ ref $v };
  croak 'Wrong option set' unless $cb;
  $c->{$_} = $cb->($v);
 }
 my $config = (exists $c->{set}) ? $c->{set} : $old;
 $config->{$_} = $c->{add}->{$_} for grep $c->{add}->{$_},
                                                keys %{$c->{add} || {}};
 delete $config->{$_} for grep $c->{rem}->{$_}, keys %{$c->{rem} || {}};
 $config;
}

sub _do {
 my $self = shift;
 my $config;
 $config->{do} = $self->_validate(\%escapes, $self->{do}, @_);
 $config->{escape} = '';
 $config->{escape} .= $escapes{$_} for keys %{$config->{do}};
 $config->{escape} = quotemeta $config->{escape};
 $config;
}

sub do {
 my $self = shift;
 _check_self $self;
 my $config = $self->_do(@_);
 $self->{$_} = $config->{$_} for keys %$config;
 $self;
}

sub _capture {
 my $self = shift;
 my $config;
 $config->{capture} = $self->_validate(\%captures, $self->{capture}, @_);
 $config->{greedy}  = delete $config->{capture}->{greedy};
 for (keys %captures) {
  $config->{'c_' . $_} = $captures{$_}->($config, $config->{capture}->{$_})
                                               if $captures{$_}; # Skip 'greedy'
 }
 $config;
}

sub capture {
 my $self = shift;
 _check_self $self;
 my $config = $self->_capture(@_);
 $self->{$_} = $config->{$_} for keys %$config;
 $self;
}

sub _type {
 my ($self, $type) = @_;
 $type = 'unix'      unless defined $type;
 croak 'Wrong type'  unless exists $types{$type};
 my $config = $self->_do($types{$type});
 $config->{type} = $type;
 $config;
}

sub type {
 my $self = shift;
 _check_self $self;
 my $config = $self->_type(@_);
 $self->{$_} = $config->{$_} for keys %$config;
 $self;
}

sub new {
 my $class = shift;
 $class = ref($class) || $class || __PACKAGE__;
 croak 'Optional arguments must be passed as key => value pairs' if @_ % 2;
 my %args = @_;
 my $self = { };
 bless $self, $class;
 if (defined $args{do}) {
  $self->do($args{do});
 } else {
  $self->type($args{type});
 }
 $self->capture($args{capture});
}

=head2 C<< new [ do => $what E<verbar> type => $type ], capture => $captures >>

Constructs a new L<Regexp::Wildcard> object.

C<do> lists all features that should be enabled when converting wildcards to regexps. Refer to L</do> for details on what can be passed in C<$what>.

The C<type> specifies a predefined set of C<do> features to use. See L</type> for details on which types are valid. The C<do> option overrides C<type>.

C<capture> lists which atoms should be capturing. Refer to L</capture> for more details.

=head2 C<< do [ $what E<verbar> set => $c1, add => $c2, rem => $c3 ] >>

Specifies the list of metacharacters to convert.
They are classified into five classes :

=over 4

=item *

C<'jokers'> converts C<?> to C<.> and C<*> to C<.*> ;

    'a**\\*b??\\?c' ==> 'a.*\\*b..\\?c'

=item *

C<'sql'> converts C<_> to C<.> and C<%> to C<.*> ;

    'a%%\\%b__\\_c' ==> 'a.*\\%b..\\_c'

=item *

C<'commas'> converts all C<,> to C<|> and puts the complete resulting regular expression inside C<(?: ... )> ;

    'a,b{c,d},e' ==> '(?:a|b\\{c|d\\}|e)'

=item *

C<'brackets'> converts all matching C<{ ... ,  ... }> brackets to C<(?: ... | ... )> alternations. If some brackets are unbalanced, it tries to substitute as many of them as possible, and then escape the remaining unmatched C<{> and C<}>. Commas outside of any bracket-delimited block are also escaped ;

    'a,b{c,d},e'    ==> 'a\\,b(?:c|d)\\,e'
    '{a\\{b,c}d,e}' ==> '(?:a\\{b|c)d\\,e\\}'
    '{a{b,c\\}d,e}' ==> '\\{a\\{b\\,c\\}d\\,e\\}'

=item *

C<'groups'> keeps the parenthesis C<( ... )> of the original string without escaping them. Currently, no check is done to ensure that the parenthesis are matching.

    'a(b(c))d\\(\\)' ==> (no change)

=back

Each C<$c> can be any of :

=over 4

=item *

A hash reference, with wanted metacharacter group names (described above) as keys and booleans as values ;

=item *

An array reference containing the list of wanted metacharacter classes ;

=item *

A plain scalar, when only one group is required.

=back

When C<set> is present, the classes given as its value replace the current object options. Then the C<add> classes are added, and the C<rem> classes removed.

Passing a sole scalar C<$what> is equivalent as passing C<< set => $what >>.
No argument means C<< set => [ ] >>.

    $rw->do(set => 'jokers');           # Only translate jokers.
    $rw->do('jokers');                  # Same.
    $rw->do(add => [ qw/sql commas/ ]); # Translate also SQL and commas.
    $rw->do(rem => 'jokers');           # Specifying both 'sql' and 'jokers' is useless.
    $rw->do();                          # Translate nothing.

=head2 C<type $type>

Notifies to convert the metacharacters that corresponds to the predefined type C<$type>. C<$type> can be any of C<'jokers'>, C<'sql'>, C<'commas'>, C<'brackets'>, C<'win32'> or C<'unix'>. An unknown or undefined value defaults to C<'unix'>, except for C<'dos'>, C<'os2'>, C<'MSWin32'> and C<'cygwin'> that default to C<'win32'>. This means that you can pass C<$^O> as the C<$type> and get the corresponding shell behaviour. Returns the object.

    $rw->type('win32'); # Set type to win32.
    $rw->type();        # Set type to unix.

=head2 C<< capture [ $captures E<verbar> set => $c1, add => $c2, rem => $c3 ] >>

Specifies the list of atoms to capture.
This method works like L</do>, except that the classes are different :

=over 4

=item *

C<'single'> will capture all unescaped I<"exactly one"> metacharacters, i.e. C<?> for wildcards or C<_> for SQL ;

    'a???b\\??' ==> 'a(.)(.)(.)b\\?(.)'
    'a___b\\__' ==> 'a(.)(.)(.)b\\_(.)'

=item *

C<'any'> will capture all unescaped I<"any"> metacharacters, i.e. C<*> for wildcards or C<%> for SQL ;

    'a***b\\**' ==> 'a(.*)b\\*(.*)'
    'a%%%b\\%%' ==> 'a(.*)b\\%(.*)'

=item *

C<'greedy'>, when used in conjunction with C<'any'>, will make the C<'any'> captures greedy (by default they are not) ;

    'a***b\\**' ==> 'a(.*?)b\\*(.*?)'
    'a%%%b\\%%' ==> 'a(.*?)b\\%(.*?)'

=item *

C<'brackets'> will capture matching C<{ ... , ... }> alternations.

    'a{b\\},\\{c}' ==> 'a(b\\}|\\{c)'

=back

    $rw->capture(set => 'single');           # Only capture "exactly one" metacharacters.
    $rw->capture('single');                  # Same.
    $rw->capture(add => [ qw/any greedy/ ]); # Also greedily capture "any" metacharacters.
    $rw->capture(rem => 'greedy');           # No more greed please.
    $rw->capture();                          # Capture nothing.

=head2 C<convert $wc [ , $type ]>

Converts the wildcard expression C<$wc> into a regular expression according to the options stored into the L<Regexp::Wildcards> object, or to C<$type> if it's supplied. It successively escapes all unprotected regexp special characters that doesn't hold any meaning for wildcards, then replace C<'jokers'> or C<'sql'> and C<'commas'> or C<'brackets'> (depending on the L</do> or L</type> options), all of this by applying the C<'capture'> rules specified in the constructor or by L</capture>.

=cut

sub convert {
 my ($self, $wc, $type) = @_;
 _check_self $self;
 my $config;
 if (defined $type) {
  $config = $self->_type($type);
 } else {
  $config = $self;
 }
 return unless defined $wc;
 my $do = $config->{do};
 my $e  = $config->{escape};
 $wc =~ s/(?<!\\)((?:\\\\)*[^\w\s\\$e])/\\$1/g;
 if ($do->{jokers}) {
  $wc = $self->_jokers($wc);
 } elsif ($do->{sql}) {
  $wc = $self->_sql($wc);
 }
 if ($do->{brackets}) {
  $wc = $self->_bracketed($wc);
 } elsif ($do->{commas}) {
  if ($wc =~ /(?<!\\)(?:\\\\)*,/) { # win32 allows comma-separated lists
   $wc = $self->{'c_brackets'} . $self->_commas($wc) . ')';
  }
 }
 return $wc;
}

=head1 EXPORT

An object module shouldn't export any function, and so does this one.

=head1 DEPENDENCIES

L<Carp> (core module since perl 5), L<Text::Balanced> (since 5.7.3).

=head1 CAVEATS

This module does not implement the strange behaviours of Windows shell that result from the special handling of the three last characters (for the file extension). For example, Windows XP shell matches C<*a> like C<.*a>, C<*a?> like C<.*a.?>, C<*a??> like C<.*a.{0,2}> and so on.

=head1 AUTHOR

Vincent Pit, C<< <perl at profvince.com> >>, L<http://www.profvince.com>.

You can contact me by mail or on #perl @ FreeNode (vincent or Prof_Vince).

=head1 BUGS

Please report any bugs or feature requests to C<bug-regexp-wildcards at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Regexp-Wildcards>. I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Regexp::Wildcards

Tests code coverage report is available at L<http://www.profvince.com/perl/cover/Regexp-Wildcards>.

=head1 COPYRIGHT & LICENSE

Copyright 2007-2008 Vincent Pit, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

sub _extract ($) { extract_bracketed $_[0], '{',  qr/.*?(?<!\\)(?:\\\\)*(?={)/ }

sub _jokers {
 my $self = shift;
 local $_ = $_[0];
 # escape an odd number of \ that doesn't protect a regexp/wildcard special char
 s/(?<!\\)((?:\\\\)*\\(?:[\w\s]|$))/\\$1/g;
 # substitute ? preceded by an even number of \
 my $s = $self->{c_single};
 s/(?<!\\)((?:\\\\)*)\?/$1$s/g;
 # substitute * preceded by an even number of \
 $s = $self->{c_any};
 s/(?<!\\)((?:\\\\)*)\*+/$1$s/g;
 return $_;
}

sub _sql {
 my $self = shift;
 local $_ = $_[0];
 # escape an odd number of \ that doesn't protect a regexp/wildcard special char
 s/(?<!\\)((?:\\\\)*\\(?:[^\W_]|\s|$))/\\$1/g;
 # substitute _ preceded by an even number of \
 my $s = $self->{c_single};
 s/(?<!\\)((?:\\\\)*)_/$1$s/g;
 # substitute % preceded by an even number of \
 $s = $self->{c_any};
 s/(?<!\\)((?:\\\\)*)%+/$1$s/g;
 return $_;
}

sub _commas {
 local $_ = $_[1];
 # substitute , preceded by an even number of \
 s/(?<!\\)((?:\\\\)*),/$1|/g;
 return $_;
}

sub _brackets {
 my ($self, $rest) = @_;
 substr $rest, 0, 1, '';
 chop $rest;
 my ($re, $bracket, $prefix) = ('');
 while (do { ($bracket, $rest, $prefix) = _extract $rest; $bracket }) {
  $re .= $self->_commas($prefix) . $self->_brackets($bracket);
 }
 $re .= $self->_commas($rest);
 return $self->{c_brackets} . $re . ')';
}

sub _bracketed {
 my ($self, $rest) = @_;
 my ($re, $bracket, $prefix) = ('');
 while (do { ($bracket, $rest, $prefix) = _extract $rest; $bracket }) {
  $re .= $prefix . $self->_brackets($bracket);
 }
 $re .= $rest;
 $re =~ s/(?<!\\)((?:\\\\)*[\{\},])/\\$1/g;
 return $re;
}

1; # End of Regexp::Wildcards
