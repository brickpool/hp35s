use strict;
use warnings;

use Test::More;
use Parser::HPC;

subtest 'macro errors reject invalid source and preserve known diagnostics' => sub {
  my @cases = (
    [ "MACRO\nENDM\n", "Missing macro ID\n" ],
    [ "MACRO TESTMACRO a,a\nENDM\n", "Duplicate dummy argument: a\n" ],
    [ "MACRO TESTMACRO 123\nENDM\n", "Illegal macro argument\n" ],
    [ "MACRO RTN\nENDM\n", undef ],
    [ "MACRO RADIX\nENDM\n", undef ],
    [ "MACRO TESTMACRO\nLOCAL 123\nENDM\n", "Illegal local argument\n" ],
    [ "MACRO OUTER\nMACRO INNER\nENDM\nENDM\n",
      "Directive not allowed inside macro definition\n" ],
    [ "ENDM\n", "Can't use this outside macro\n" ],
    [ "MACRO TESTMACRO\nENDM\nMODEL P35S\nSEGMENT CODE\nXEQ TESTMACRO\nENDS\nEND\n",
      "Can't use macro name in expression: TESTMACRO\n" ],
  );
  for my $case (@cases) {
    my ($source, $expected_error) = @$case;
    my $success = eval { Parser::HPC->new->from_string($source); 1 };
    my $error = "$@";
    ok( !$success, 'invalid macro source is rejected' );
    is( $error, $expected_error, 'exact diagnostic is reported' )
      if defined $expected_error;
  }
};

subtest 'MASM macro syntax is rejected' => sub {
  my $source = <<'ASM';
MODEL P35S
SEGMENT CODE
M MACRO
  RTN
ENDM
ENDS
END
ASM
  my $success = eval { Parser::HPC->new->from_string($source); 1 };
  ok( !$success, 'MASM-style definition is not accepted' );
};

subtest 'EXITM is not a supported directive' => sub {
  my $source = <<'ASM';
MODEL P35S
SEGMENT CODE
EXITM
ENDS
END
ASM
  my $success = eval { Parser::HPC->new->from_string($source); 1 };
  my $error = "$@";
  ok( !$success, 'EXITM is rejected as a code statement' );
  like( $error, qr/Illegal instruction/,
    'EXITM does not use the macro-only directive diagnostic' );
};

done_testing;