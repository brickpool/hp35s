package Parser::HPC::Vocabulary;
# ABSTRACT: HPC-specific assembler vocabulary

use strict;
use warnings;

use version;
our $VERSION = version->declare('v0.5.2');

use Exporter 'import';
our @EXPORT_OK = qw(
  @directives
  @predefined
  @languages
  @segments
  @listings
  @modes
  @models
);

our @directives = (
  'DISPLAY', 'END', 'ENDM', 'EQU', '%LINUM', 'LOCALS', 'MACRO', 
  'MODEL', 'NOLOCALS', 'RADIX', 'SET',
);

our @predefined = (
  '??date', '??filename', '??time', '??version',
);

our @languages = (
  'P35S',
);

our @segments = (
  'DATASEG', 'CODESEG', 'STACK',
);

our @listings = (
  '%SYMS', '%NOSYMS',   # default = true
  '%TITLE', '%SUBTTL',  # default = undef
  '%NEWPAGE',

  # %PAGESIZE [rows] [,cols]
  # rows = 66
  # cols = 132
  '%PAGESIZE', 

  # <depth> <line number> <offset> <machine code> <source> 
  # %DEPTH   = 1       default
  # %LINUM   = 4       default
  # %PCNT    = 4       16-Bit-Segments
  # %BIN     = 20      default
  '%DEPTH', '%LINUM', '%PCNT', '%BIN', '%TEXT',

  # %TABSIZE default 8
  '%TABSIZE', 
);

our @modes = (
  'IDEAL', 'MASM',
);

our @models = (
  'TINY', 'SMALL', 'COMPACT', 'MEDIUM', 'LARGE', 'HUGE',
);

1;

__END__

=head1 NAME

Parser::HPC::Vocabulary - HPC-specific assembler vocabulary

=head1 DESCRIPTION

This module provides the directives, predefined symbols, language names, and 
segment names used by the HPC assembler parser.

HP-35s instructions and constants are provided by L<HP35s::Vocabulary>.

=head1 EXPORTS

C<@directives>, C<@predefined>, C<@languages> and C<@segments> are available on 
request.

=cut
