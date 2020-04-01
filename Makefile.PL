#! perl

use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;

WriteMakefile(
  NAME                => 'Parser::HPC',
  AUTHOR              => 'J. Schneider',
  VERSION_FROM        => 'asm2hpc.pl',
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
  LICENSE           => 'mit',
);
