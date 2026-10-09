#!perl
use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;

WriteMakefile(
  NAME                => 'HP35s',
  AUTHOR              => 'J. Schneider',
  VERSION_FROM        => 'bin/asm2hpc.pl',
  ABSTRACT            => 'Parsing HP-35s assembler file to creating RPN listings',
  CONFIGURE_REQUIRES  => {
    'ExtUtils::MakeMaker' => 6.64,
  },
  BUILD_REQUIRES      => {
    'ExtUtils::Install'   => 1.54,
    'ExtUtils::Command'   => 1.17,
    'ExtUtils::Manifest'  => 1.58,
  },
  PREREQ_PM           => {
    'strict'              => 1.04,
    'warnings'            => 1.09,
    'Exporter'            => 5.6401,
    'Parser::MGC'         => 0.16,
  },
  LICENSE             => 'mit',

  META_MERGE => {
    'meta-spec' => { 
      version => 2 
    },
    homepage  => 'http://brickpool.de',
    resources => {
      repository  => {
        type => 'git',
        url  => 'https://github.com/brickpool/hp35s.git',
        web  => 'https://github.com/brickpool/hp35s',
      },
      bugtracker  => { 
        web => 'https://github.com/brickpool/hp35s/issues',
      },
    },
    provides => {
      'Parser::HPC'
        => { file => 'lib/Parser/HPC.pm', version => '0.5.0' },
      'Parser::HPC::Macro'
        => { file => 'lib/Parser/HPC/Macro.pm', version => '0.5.0' },
      'Parser::HPC::Vocabulary'
        => { file => 'lib/Parser/HPC/Vocabulary.pm', version => '0.5.0' },
      'HP35s::Charset'
        => { file => 'lib/HP35s/Charset.pm', version => '0.5.0' },
      'HP35s::Vocabulary'
        => { file => 'lib/HP35s/Vocabulary.pm', version => '0.5.0' },
      'HP35s::Macro'
        => { file => 'lib/HP35s/Macro.pm', version => '0.5.0' },
      'HP35s::Render'
        => { file => 'lib/HP35s/Render.pm', version => '0.5.0' },
      'HP35s::Keystrokes'
        => { file => 'lib/HP35s/Keystrokes.pm', version => '0.5.0' },
    },
    prereqs => {
      runtime => {
        requires => {
          'Parser::MGC' => 0.16,
        },
      },
    },
  },

  dist => {
    TARFLAGS => '-cvzf',
    COMPRESS => 'perl -MExtUtils::Command -e test_f',
    POSTOP   => 'perl -MExtUtils::Command -e mv $(DISTVNAME).tar $(DISTVNAME).tar$(SUFFIX)'
  },

);
