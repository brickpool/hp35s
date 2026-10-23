use strict;
use warnings;

use Test::More;
use Test::Exception;
use Parser::HPC;

subtest 'RADIX affects EQU values but not decimal instruction operands' => sub {
  my $root = Parser::HPC->new->from_string(<<'ASM');
MODEL TINY
RADIX 16
DATASEG
  VALUE EQU 100
RADIX 2
  OTHER EQU 100
CODESEG
  CF 11
RADIX 16
  FIX 11
  SF 10
END
ASM

  my $definitions = $root->{segments}->[0]->{definitions};
  is( $definitions->[0]->{value}, 256, 'RADIX 16 applies to EQU' );
  is( $definitions->[1]->{value}, 4, 'RADIX 2 applies to following EQU' );

  my $statements = $root->{segments}->[1]->{statements};
  is( $statements->[0]->{instruction}->{operand}->{value}, 11,
    'CF operand remains decimal' );
  is( $statements->[1]->{instruction}->{operand}->{value}, 11,
    'FIX operand remains decimal' );
  is( $statements->[2]->{instruction}->{operand}->{value}, 10,
    'SF operand remains decimal' );
};

subtest 'RADIX state persists when a parser instance is reused' => sub {
  my $parser = Parser::HPC->new;

  $parser->from_string(<<'ASM');
MODEL TINY
CODESEG
RADIX 16
  100
END
ASM

  my $next = $parser->from_string(<<'ASM');
MODEL TINY
CODESEG
  100
END
ASM

  is_deeply(
    $next->{segments}->[0]->{statements}->[0],
    { literal => { kind => 'hex', value => '100h' } },
    'reused parser retains RADIX 16',
  );

  my $fresh = Parser::HPC->new->from_string(<<'ASM');
MODEL TINY
CODESEG
  100
END
ASM

  is_deeply(
    $fresh->{segments}->[0]->{statements}->[0],
    { literal => { kind => 'decimal', value => '100' } },
    'new parser starts with decimal radix',
  );
};

subtest 'invalid numeric syntax is rejected under the active RADIX' => sub {
  for my $case (
    [ 2,  '102'  ],
    [ 8,  '89'   ],
    [ 16, '12G'  ],
    [ 16, '12ab' ],
  ) {
    my ($base, $value) = @$case;
    my $source = "MODEL TINY\nCODESEG\nRADIX $base\n$value\nEND\n";

    dies_ok {
      Parser::HPC->new->from_string($source);
    } "RADIX $base rejects $value";
  }
};

subtest 'non-decimal RADIX rejects unsuffixed decimal floats' => sub {
  for my $base ( 2, 8, 16 ) {
    my $source = "MODEL TINY\nDATASEG\nRADIX $base\nVALUE EQU 7e-1\nEND\n";

    dies_ok {
      Parser::HPC->new->from_string($source);
    } "RADIX $base rejects decimal float";
  }
};

done_testing;
