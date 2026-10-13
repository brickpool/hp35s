use strict;
use warnings;

use Test::More;
use Parser::HPC;

sub parse_statements {
  my $code = shift;
  my $data = shift || '';
  my $parser = Parser::HPC->new;
  my $root = $parser->from_string(
    "MODEL P35S\n$data\nSEGMENT CODE\n$code\nENDS\nEND\n"
  );
  return $root->{segments}->[-1]->{statements};
}

subtest 'segment ASTs preserve source order' => sub {
  my $root = Parser::HPC->new->from_string(<<'ASM');
MODEL P35S
SEGMENT zebra CODE
entry:
  RTN
ENDS zebra
RADIX 10
LOCALS
NOLOCALS
SEGMENT DATA
  FORMULA EQU 'A+B'
ENDS
SEGMENT STACK
  REGX SET 2
ENDS
SEGMENT CODE
  STOP
ENDS
END entry
ASM
  is_deeply( $root->{segments}, [
    { name => 'ZEBRA', type => 'code', statements => [
      { label => { name => 'ENTRY' } },
      { instruction => { value => 'RTN' } },
    ] },
    { name => '_DATA', type => 'data', definitions => [
      { name => 'FORMULA', type => 'equation', value => 'A+B' },
    ] },
    { name => 'STACK', type => 'stack', assignments => {
      REGX => { type => 'register', value => 2 },
    } },
    { name => '_TEXT', type => 'code', statements => [
      { instruction => { value => 'STOP' } },
    ] },
  ], 'named and default segments are explicit nodes in source order' );
  ok( !exists $root->{labels}, 'AST contains no derived label index' );
};

subtest 'definition ASTs preserve names and source order' => sub {
  my $root = Parser::HPC->new->from_string(<<'ASM');
MODEL P35S
SEGMENT DATA
  eqnZulu EQU 'A+B'
  RADIX 16
  LOCALS
  alpha EQU 100
  NOLOCALS
  RADIX 10
  middle EQU 2
ENDS
END
ASM
  is_deeply( $root->{segments}->[0]->{definitions}, [
    { name => 'eqnZulu', type => 'equation', value => 'A+B' },
    { name => 'alpha', type => 'equation', value => 256 },
    { name => 'middle', type => 'equation', value => 2 },
  ], 'definitions retain spelling, values and source order without directive entries' );
};

subtest 'instruction ASTs' => sub {
  my @cases = (
    [ 'RTN', 'RTN', undef ],
    [ 'REGX', 'REGX', undef ],
    [ 'SIN', 'SIN', undef ],
    [ 'GTO A001', 'GTO',
      { type => 'address', value => 'A001' } ],
    [ 'XEQ target', 'XEQ',
      { type => 'label', value => 'TARGET' } ],
    [ 'LBL A', 'LBL',
      { type => 'variable', value => 'A' } ],
    [ 'FIX 0', 'FIX',
      { type => 'decimal', value => '0' } ],
    [ 'CF 11', 'CF',
      { type => 'decimal', value => '11' } ],
    [ 'STO (I)', 'STO',
      { type => 'variable', value => '(I)' } ],
    [ 'VIEW A', 'VIEW',
      { type => 'variable', value => 'A' } ],
    [ "eqn 'A+B'", 'eqn',
      { type => 'expression', value => 'A+B' } ],
    [ 'eqn FORMULA', 'eqn',
      { type => 'equation', value => 'FORMULA' } ],
  );
  for my $case ( @cases ) {
    my ($code, $mnemonic, $operand) = @$case;
    my $instruction = { value => $mnemonic };
    $instruction->{operand} = $operand if defined $operand;
    is_deeply( parse_statements($code,
      "SEGMENT DATA\nFORMULA EQU 'A+B'\nENDS")->[0], {
        instruction => $instruction,
      }, $code );
  }
};

subtest 'literal ASTs' => sub {
  my @cases = (
    [ 'pi', 'constant' ], [ 'i', 'constant' ], [ 'e', 'constant' ],
    [ '[1,2]', 'vector' ], [ '[3,4,5]', 'vector' ],
    [ '0110b', 'binary' ], [ '7012o', 'octal' ], [ '12ABh', 'hex' ],
    [ '1i2', 'complex' ], [ '3t4', 'complex' ],
    [ '0', 'decimal' ], [ '2.3', 'decimal' ], [ '4e5', 'decimal', 400000 ],
    [ '-6', 'decimal' ], [ '7e-1', 'decimal', 0.7 ],
    [ '12d', 'decimal' ], [ '-12d', 'decimal' ],
  );
  for my $case ( @cases ) {
    my ($value, $kind, $parsed_value) = @$case;
    $parsed_value = $value unless defined $parsed_value;
    is_deeply( parse_statements($value)->[0], {
      literal => { kind => $kind, value => $parsed_value },
    }, $value );
  }
};

subtest 'mixed statements and labels' => sub {
  my $parser = Parser::HPC->new;
  my $root = $parser->from_string(
    "MODEL P35S\nSEGMENT CODE\nentry:\nLBL A\n0 ; zero\n\npi\nGTO entry\nRTN\nENDS\nEND entry\n"
  );
  is( scalar @{ $root->{segments}->[0]->{statements} }, 6,
    'alternatives parse successive lines and comments' );
  is_deeply( $root->{segments}->[0]->{statements}->[0], {
    label => { name => 'ENTRY' },
  }, 'label declaration precedes the first instruction' );
  is_deeply( $root->{startaddr}, { type => 'label', value => 'ENTRY' },
    'start label is a typed reference' );
};

subtest 'label declarations preserve order around directives' => sub {
  my $root = Parser::HPC->new->from_string(<<'ASM');
MODEL P35S
SEGMENT CODE
start:
alias:
  RADIX 16
  LOCALS
  @@loop:
    100
  NOLOCALS
last:
  RTN
ENDS
END start
ASM
  is_deeply( $root->{segments}->[0]->{statements}, [
    { label => { name => 'START' } },
    { label => { name => 'ALIAS' } },
    { label => { name => 'ALIAS:@@LOOP' } },
    { literal => { kind => 'hex', value => '100h' } },
    { label => { name => 'LAST' } },
    { instruction => { value => 'RTN' } },
  ], 'declarations are ordered nodes and local names remain qualified' );
};

subtest 'END start reference is optional' => sub {
  for my $target ( '', 'entry', 'EnTrY' ) {
    my $root = Parser::HPC->new->from_string(
      "MODEL P35S\nSEGMENT CODE\nentry:\nRTN\nENDS\nEND $target\n"
    );
    if ( length $target ) {
      is_deeply( $root->{startaddr}, { type => 'label', value => 'ENTRY' },
        "END $target normalizes the referenced label" );
    } else {
      ok( !exists $root->{startaddr}, 'END without a label omits startaddr' );
    }
  }
};

subtest 'statement line boundary accepts whitespace and comments' => sub {
  for my $code (
    'RTN   ; return',
    '0   ; zero',
    'pi   ; constant',
    'GTO start   ; jump',
    'RTN   ',
  ) {
    my $parser = Parser::HPC->new;
    my $source = <<ASM;
; One statement per line; comments and whitespace are permitted
MODEL P35S
SEGMENT main CODE
start:
  LBL C
  $code

  ; The next statement must remain separate
  STOP
ENDS main
END start
ASM
    my $root;
    my $success = eval { $root = $parser->from_string($source); 1 };
    my $error = "$@";
    ok( $success, "$code accepts whitespace and comments" );
    is( $error, '', 'no parse failure' );
    is( scalar @{ $root->{segments}->[0]->{statements} }, 4,
      'following statement is parsed separately' ) if $success;
  }
};

done_testing;