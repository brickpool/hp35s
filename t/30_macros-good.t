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
  my $statements = $root->{segments}->[0]->{statements};
  is( $statements->[1]->{instruction}->{operand}->{value}, '??0000',
    'a reference before LOCAL receives the generated name' );
  is( $statements->[3]->{instruction}->{operand}->{value}, 'TARGET',
    'the macro still references its external target' );
  is_deeply( $statements->[2], { label => { name => '??0000' } },
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
  my $statements = $root->{segments}->[0]->{statements};
  is( $statements->[0]->{instruction}->{operand}->{value}, '??0000',
    'the first LOCAL directive gets a unique name' );
  is( $statements->[2]->{instruction}->{operand}->{value}, '??0001',
    'the second LOCAL directive gets another unique name' );
  is_deeply( $statements->[1], { label => { name => '??0000' } },
    'the first local label resolves' );
  is_deeply( $statements->[3], { label => { name => '??0001' } },
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
  my $statements = $root->{segments}->[0]->{statements};
  is( $statements->[2]->{instruction}->{operand}->{value}, 'TARGET',
    'first expansion jumps to an external label' );
  is( $statements->[4]->{instruction}->{operand}->{value}, '??0001',
    'first expansion references its local done label' );
  is( $statements->[6]->{instruction}->{operand}->{value}, '??0000',
    'first expansion references its local again label' );
  is( $statements->[7]->{instruction}->{operand}->{value}, 'TARGET',
    'second expansion jumps to the same external label' );
  is( $statements->[9]->{instruction}->{operand}->{value}, '??0003',
    'second expansion references its own done label' );
  is( $statements->[11]->{instruction}->{operand}->{value}, '??0002',
    'second expansion references its own again label' );
  is_deeply( $statements->[3], { label => { name => '??0000' } },
    'first again label is registered' );
  is_deeply( $statements->[5], { label => { name => '??0001' } },
    'first done label is registered' );
  is_deeply( $statements->[8], { label => { name => '??0002' } },
    'second again label is registered' );
  is_deeply( $statements->[10], { label => { name => '??0003' } },
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
  is( $root->{segments}->[0]->{statements}->[2]->{instruction}->{operand}->{value},
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
  my $statements = $root->{segments}->[0]->{statements};
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
  is( $root->{segments}->[0]->{statements}->[2]->{instruction}->{operand}->{value},
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
  is( $root->{segments}->[0]->{statements}->[0]->{instruction}->{operand}->{value},
    'MYMAC', 'string contents and comments are skipped by the macro reference parser' );
};

subtest 'normal whitespace handling preserves ordinary source tokens' => sub {
  my $parser = Parser::HPC::Macro->new(
    patterns => { ident => Parser::HPC::pattern_ident() },
  );
  for my $source ('', " \t", '; comment', "\tRTN \t",
    " \t; comment\n\n  RTN\n \t", "  RTN\r\n\tSTOP\r\n", "  RTN\r\tSTOP\r") {
    my $code = $source;
    $code =~ s/;[^\r\n]*//g;
    is_deeply( [ grep { length } split /\s+/, $parser->from_string($source) ],
      [ grep { length } split /\s+/, $code ], 'ordinary code tokens are unchanged' );
  }
};

subtest 'macro scopes preserve every supported line ending' => sub {
  for my $ending ("\n", "\r", "\r\n") {
    my $parser = Parser::HPC::Macro->new(
      patterns => { ident => Parser::HPC::pattern_ident() },
    );
    my $source = join $ending,
      'MACRO BRANCH target', '  GTO target', '  ENDM', 'BRANCH done', " \t";
    is( $parser->from_string($source),
      "GTO done\n",
      'supported line endings are normalized for normal whitespace handling' );
  }
};

subtest 'substitution respects whole symbols and preserves surrounding text' => sub {
  my $parser = Parser::HPC::Macro->new(
    patterns => { ident => Parser::HPC::pattern_ident() },
  );
  my $source = <<'ASM';
MACRO REPLACE Arg
  GTO ARG ; ARG, ARGExtra, 1ARG, @ARG, $ARG, ?ARG, _ARG
  eqn 'ARG ARGExtra 1ARG @ARG $ARG ?ARG _ARG'
ENDM
REPLACE done
ASM
  is( $parser->from_string($source),
    <<'ASM', 'only complete symbols are replaced without changing other text' );
GTO done
eqn 'done ARGExtra 1ARG @ARG $ARG ?ARG _ARG'
ASM
};

subtest 'replacement values are not interpreted as further dummy arguments' => sub {
  my $parser = Parser::HPC::Macro->new(
    patterns => { ident => Parser::HPC::pattern_ident() },
  );
  my $source = <<'ASM';
MACRO REPLACE first,second
  GTO first
  GTO second
ENDM
REPLACE second,done
ASM
  is( $parser->from_string($source),
    "GTO second\nGTO done\n",
    'each body token is substituted exactly once' );
};

subtest 'only LOCAL is interpreted within a macro body' => sub {
  my $parser = Parser::HPC::Macro->new(
    patterns => { ident => Parser::HPC::pattern_ident() },
  );
  my $source = <<'ASM';
MACRO OUTER
  LOCAL label ; a local declaration with a comment,
MACRO INNER
  UNKNOWN statement
  eqn 'ENDM'
  ; LOCAL is only a comment
label:
ENDM
OUTER
ASM
  is( $parser->from_string($source), <<'ASM', 'only LOCAL is interpreted' );
MACRO INNER
UNKNOWN statement
eqn 'ENDM'
??0000:
ASM
};

subtest 'LOCAL labels and dummy arguments have separate replacement contexts' => sub {
  my $parser = Parser::HPC::Macro->new(
    patterns => { ident => Parser::HPC::pattern_ident() },
  );
  my $source = <<'ASM';
MACRO MIXED target
  LOCAL target,TARGET
  LOCAL target
target: GTO target
  XEQ TARGET
  STO target
  eqn 'target' ; GTO target
ENDM
MIXED A
MIXED B
ASM
  is( $parser->from_string($source), <<'ASM', 'locals apply only to declarations and address operands' );
??0000: GTO ??0000
XEQ ??0000
STO A
eqn 'A' ; GTO A
??0001: GTO ??0001
XEQ ??0001
STO B
eqn 'B' ; GTO B
ASM
};

subtest 'dummy argument duplicate checks are case-insensitive' => sub {
  my $parser = Parser::HPC::Macro->new(
    patterns => { ident => Parser::HPC::pattern_ident() },
  );
  for my $case ([ 'name', 'Name' ], [ 'name', 'NAME' ], [ 'Name', 'NAME' ]) {
    my ($first, $second) = @$case;
    my $success = eval {
      $parser->from_string("MACRO DISTINCT $first,$second\nENDM\n"); 1;
    };
    ok( !$success, "$first and $second are duplicate dummy arguments" );
    like( "$@", qr/\ADuplicate dummy argument: \Q$second\E/,
      'duplicate detection reports the repeated spelling' );
  }
};

subtest 'macro names are case-insensitive' => sub {
  my $parser = Parser::HPC::Macro->new(
    patterns => { ident => Parser::HPC::pattern_ident() },
  );
  is( $parser->from_string("MACRO Case\nSTOP\nENDM\ncase\n"),
    "STOP\n", 'a differently cased invocation resolves the macro' );
};

done_testing;
