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
  return $root->{segments}->{_TEXT}->{statements};
}

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
    [ '0', 'decimal' ], [ '2.3', 'decimal' ], [ '4e5', 'decimal' ],
    [ '-6', 'decimal' ], [ '7e-1', 'decimal' ], [ '12d', 'decimal' ],
  );
  for my $case ( @cases ) {
    my ($value, $kind) = @$case;
    is_deeply( parse_statements($value)->[0], {
      literal => { kind => $kind, value => $value },
    }, $value );
  }
};

subtest 'mixed statements and labels' => sub {
  my $parser = Parser::HPC->new;
  my $root = $parser->from_string(
    "MODEL P35S\nSEGMENT CODE\nentry:\nLBL A\n0 ; zero\n\npi\nGTO entry\nRTN\nENDS\nEND entry\n"
  );
  is( scalar @{ $root->{segments}->{_TEXT}->{statements} }, 5,
    'alternatives parse successive lines and comments' );
  is_deeply( $root->{labels}->{ENTRY}, {
    type => 'near', segment => '_TEXT', statement => 0,
  }, 'label still refers to the first statement' );
  is( $root->{startaddr}, 'ENTRY', 'start label preserved' );
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
    is( scalar @{ $root->{segments}->{MAIN}->{statements} }, 3,
      'following statement is parsed separately' ) if $success;
  }
};

done_testing;