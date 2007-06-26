use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Regexp::Wildcards',
    AUTHOR              => 'Vincent Pit <perl@profvince.com>',
    LICENSE             => 'perl',
    VERSION_FROM        => 'lib/Regexp/Wildcards.pm',
    ABSTRACT_FROM       => 'lib/Regexp/Wildcards.pm',
    PL_FILES            => {},
    PREREQ_PM           => {
        'Test::More' => 0,
        'Text::Balanced' => 0,
    },
    dist                => {
        PREOP => 'pod2text lib/Regexp/Wildcards.pm > $(DISTVNAME)/README',
        COMPRESS => 'gzip -9f', SUFFIX => 'gz'
    },
    clean               => { FILES => 'Regexp-Wildcards-*' },
);
