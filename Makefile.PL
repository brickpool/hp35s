#!perl
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile1(
  NAME                => 'HP35s',
  ABSTRACT            => 'Parsing HP-35s assembler to creating RPN listings',
  AUTHOR              => 'J. Schneider',
  VERSION_FROM        => 'bin/asm2hpc.pl',
  MIN_PERL_VERSION    => '5.014',
  LICENSE             => 'mit',
  EXE_FILES           => ['bin/asm2hpc.pl'],

  CONFIGURE_REQUIRES  => {
    'ExtUtils::MakeMaker' => 6.64,
  },

  BUILD_REQUIRES => {
    'ExtUtils::Install'   => 1.54,
    'ExtUtils::Command'   => 1.17,
    'ExtUtils::Manifest'  => 1.58,
  },

  PREREQ_PM => {
    'Exporter'       => 5.6401,
    'Parser::MGC'    => 0.16,
    'Storable'       => 2.27,
    'Text::Balanced' => 1.76,
  },

  TEST_REQUIRES => {
    'Cwd'             => 0,
    'File::Path'      => 0,
    'Find::File'      => 0,
    'Test::More'      => 0,
    'Test::Exception' => 0,
  },

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
        => { file => 'lib/Parser/HPC.pm', version => '0.5.4' },
      'Parser::HPC::Vocabulary'
        => { file => 'lib/Parser/HPC/Vocabulary.pm', version => '0.5.4' },
      'HP35s::Charset'
        => { file => 'lib/HP35s/Charset.pm', version => '0.5.4' },
      'HP35s::Vocabulary'
        => { file => 'lib/HP35s/Vocabulary.pm', version => '0.5.4' },
      'HP35s::Macro'
        => { file => 'lib/HP35s/Macro.pm', version => '0.5.4' },
      'HP35s::Render'
        => { file => 'lib/HP35s/Render.pm', version => '0.5.4' },
      'HP35s::Keystrokes'
        => { file => 'lib/HP35s/Keystrokes.pm', version => '0.5.4' },
    },
    prereqs => {
      runtime => {
        requires => {
          'constant'       => 0,
          'Data::Dumper'   => 0,
          'Encode'         => 0,
          # 'File::Basename' => 0,
          'Getopt::Long'   => 0,
          'lib'            => 0,
          'Pod::Usage'     => 0,
          # 'POSIX'          => 0,
          'strict'         => 1.04,
          # 'utf8'           => 0,
          'version'        => 0,
          'warnings'       => 1.09,
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

# Cribbed from eumm-upgrade by Alexandr Ciornii
sub WriteMakefile1 {    # void (%params)
  my %params = @_;
  my $eumm_version = $ExtUtils::MakeMaker::VERSION;
  $eumm_version = eval $eumm_version;

  if ($params{TEST_REQUIRES} and $eumm_version < 6.6303) {
    $params{BUILD_REQUIRES} = {
      %{$params{BUILD_REQUIRES} || {}} , 
      %{$params{TEST_REQUIRES}}
    };
    delete $params{TEST_REQUIRES};
  }
  if ($params{BUILD_REQUIRES} and $eumm_version < 6.5503) {
    # EUMM 6.5502 has problems with BUILD_REQUIRES
    $params{PREREQ_PM} = {
      %{$params{PREREQ_PM} || {}} , 
      %{$params{BUILD_REQUIRES}}
    };
    delete $params{BUILD_REQUIRES};
  }

  delete $params{CONFIGURE_REQUIRES} if $eumm_version < 6.52;
  delete $params{MIN_PERL_VERSION} if $eumm_version < 6.48;
  delete $params{META_MERGE} if $eumm_version < 6.46;
  delete $params{META_ADD} if $eumm_version < 6.46;
  delete $params{LICENSE} if $eumm_version < 6.31;
  delete $params{AUTHOR} if $] < 5.005;
  delete $params{ABSTRACT_FROM} if $] < 5.005;
  delete $params{BINARY_LOCATION} if $] < 5.005;

  WriteMakefile(%params);
}
