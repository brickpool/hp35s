use strict;
use warnings;

use Test::More;
use Parser::HPC;

sub parse_source {
  my ($source) = @_;
  return Parser::HPC->new->from_string($source);
}

subtest 'LOCAL may follow an initial body reference' => sub {
  my $root = parse_source(<<'ASM');
MACRO LATE target
  GTO again
  LOCAL again
again:
  GTO target
ENDM
MODEL P35S
SEGMENT CODE

  RTN
LATE target
ENDS
END
ASM
  my $statements = $root->{segments}->{_TEXT}->{statements};
  is( $statements->[1]->{instruction}->{operand}->{value}, '??0000',
    'a reference before LOCAL receives the generated name' );
  is( $statements->[2]->{instruction}->{operand}->{value}, 'TARGET',
    'the macro still references its external target' );
  is( $root->{labels}->{'??0000'}->{statement}, 2,
    'the later local declaration applies to the full macro body' );
};

subtest 'a macro may contain multiple LOCAL directives' => sub {
  my $root = parse_source(<<'ASM');
MACRO TEST
  LOCAL first
  LOCAL second
  GTO first
first:
  GTO second
second:
  RTN
ENDM
MODEL P35S
SEGMENT CODE
TEST
ENDS
END
ASM
  my $statements = $root->{segments}->{_TEXT}->{statements};
  is( $statements->[0]->{instruction}->{operand}->{value}, '??0000',
    'the first LOCAL directive gets a unique name' );
  is( $statements->[1]->{instruction}->{operand}->{value}, '??0001',
    'the second LOCAL directive gets another unique name' );
  is( $root->{labels}->{'??0000'}->{statement}, 1,
    'the first local label resolves' );
  is( $root->{labels}->{'??0001'}->{statement}, 2,
    'the second local label resolves' );
};

subtest 'LOCAL labels are unique per expansion and external labels remain usable' => sub {
  my $root = parse_source(<<'ASM');
MACRO TEST target
  LOCAL again, done
  GTO target
again:
  GTO done
done:
  GTO again
ENDM
MODEL P35S
SEGMENT CODE
target:
  RTN
TEST target
TEST target
ENDS
END
ASM
  my $statements = $root->{segments}->{_TEXT}->{statements};
  is( $statements->[1]->{instruction}->{operand}->{value}, 'TARGET',
    'first expansion jumps to an external label' );
  is( $statements->[2]->{instruction}->{operand}->{value}, '??0001',
    'first expansion references its local done label' );
  is( $statements->[3]->{instruction}->{operand}->{value}, '??0000',
    'first expansion references its local again label' );
  is( $statements->[4]->{instruction}->{operand}->{value}, 'TARGET',
    'second expansion jumps to the same external label' );
  is( $statements->[5]->{instruction}->{operand}->{value}, '??0003',
    'second expansion references its own done label' );
  is( $statements->[6]->{instruction}->{operand}->{value}, '??0002',
    'second expansion references its own again label' );
  is( $root->{labels}->{'??0000'}->{statement}, 2,
    'first again label is registered' );
  is( $root->{labels}->{'??0001'}->{statement}, 3,
    'first done label is registered' );
  is( $root->{labels}->{'??0002'}->{statement}, 5,
    'second again label is registered' );
  is( $root->{labels}->{'??0003'}->{statement}, 6,
    'second done label is registered' );
};

subtest 'simple dummy arguments are substituted' => sub {
  my $root = parse_source(<<'ASM');
MACRO CALL target
  XEQ target
ENDM
MODEL P35S
SEGMENT CODE
target:
  RTN
CALL target
ENDS
END
ASM
  is( $root->{segments}->{_TEXT}->{statements}->[1]->{instruction}->{operand}->{value},
    'TARGET', 'plain argument substitution reaches the instruction operand' );
};

subtest 'multiline macros can be redefined' => sub {
  my $root = parse_source(<<'ASM');
MACRO ACTION
  RTN
ENDM
MODEL P35S
SEGMENT CODE
ACTION
MACRO ACTION
  STOP
ENDM
ACTION
ENDS
END
ASM
  my $statements = $root->{segments}->{_TEXT}->{statements};
  is_deeply( [ map { $_->{instruction}->{value} } @$statements ],
    [ 'RTN', 'STOP' ],
    'an earlier invocation keeps its expansion and later calls use the replacement' );
};

subtest 'macro identifiers use the HPC identifier pattern' => sub {
  my $root = parse_source(<<'ASM');
MACRO @CALL target
  XEQ target
ENDM
MODEL P35S
SEGMENT CODE
target:
  RTN
@CALL target
ENDS
END
ASM
  is( $root->{segments}->{_TEXT}->{statements}->[1]->{instruction}->{operand}->{value},
    'TARGET', 'macro names accept the same identifier syntax as HPC' );
};

subtest 'macro names in strings and comments are not expression references' => sub {
  my $root = parse_source(<<'ASM');
MACRO MYMAC
  RTN
ENDM
MODEL P35S
SEGMENT CODE
  eqn 'MYMAC' ; MYMAC is a comment
ENDS
END
ASM
  is( $root->{segments}->{_TEXT}->{statements}->[0]->{instruction}->{operand}->{value},
    'MYMAC', 'string contents and comments are skipped by the macro reference parser' );
};

done_testing;
