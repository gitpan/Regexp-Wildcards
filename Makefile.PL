use strict;
use warnings;
use ExtUtils::MakeMaker;

my $dist = 'Regexp-Wildcards';

my %META = (
 configure_requires => {
  'ExtUtils::MakeMaker' => 0,
 },
 build_requires => {
  'ExtUtils::MakeMaker' => 0,
  'Test::More'          => 0,
 },
 resources => {
  bugtracker => "http://rt.cpan.org/NoAuth/ReportBug.html?Queue=$dist",
  homepage   => "http://search.cpan.org/dist/$dist/",
  license    => 'http://dev.perl.org/licenses/',
  repository => "http://git.profvince.com/perl/modules/$dist.git",
 },
);

WriteMakefile(
    NAME             => 'Regexp::Wildcards',
    AUTHOR           => 'Vincent Pit <perl@profvince.com>',
    LICENSE          => 'perl',
    VERSION_FROM     => 'lib/Regexp/Wildcards.pm',
    ABSTRACT_FROM    => 'lib/Regexp/Wildcards.pm',
    PL_FILES         => {},
    PREREQ_PM        => {
        'Carp'           => 0,
        'Text::Balanced' => 0,
    },
    MIN_PERL_VERSION => 5.006,
    META_MERGE       => \%META,
    dist             => {
        PREOP    => 'pod2text lib/Regexp/Wildcards.pm > $(DISTVNAME)/README',
        COMPRESS => 'gzip -9f', SUFFIX => 'gz'
    },
    clean            => {
        FILES => "$dist-* *.gcov *.gcda *.gcno cover_db Debian_CPANTS.txt"
    },
);
