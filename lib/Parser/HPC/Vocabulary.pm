package Parser::HPC::Vocabulary;
# ABSTRACT: HPC-specific assembler vocabulary

use strict;
use warnings;

use version;
our $VERSION = version->declare('v0.5.1');

use Exporter 'import';
our @EXPORT_OK = qw(
  @directives
  @predefined
  @languages
  @segments
);

our @directives = (
  'DISPLAY', 'END', 'ENDM', 'EQU', 'IDEAL', 'LOCALS', 'MACRO', 'MODEL', 
  'NOLOCALS', 'RADIX', 'SET', '%TITLE',
);

our @predefined = (
  '??date', '??time',
);

our @languages = (
  'P35S',
);

our @segments = (
  'DATASEG', 'CODESEG', 'STACK',
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
