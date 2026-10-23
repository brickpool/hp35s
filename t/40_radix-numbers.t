use strict;
use warnings;

use Test::More;
use Parser::HPC;

subtest 'RADIX selects the base for unsuffixed integers' => sub {
  my %cases = (
    2  => [ 'binary',  '100b' ],
    8  => [ 'octal',   '100o' ],
    10 => [ 'decimal', '100'  ],
    16 => [ 'hex',     '100h' ],
  );

  for my $base ( 2, 8, 10, 16 ) {
    my $root = Parser::HPC->new->from_string(<<ASM);
MODEL TINY
CODESEG
RADIX $base
  100
END
ASM

    is_deeply(
      $root->{segments}->[0]->{statements}->[0],
      { literal => { kind => $cases{$base}->[0], value => $cases{$base}->[1] } },
      "RADIX $base selects $cases{$base}->[0]",
    );
  }
};

subtest 'explicit numeric suffixes take precedence over RADIX' => sub {
  my $root = Parser::HPC->new->from_string(<<'ASM');
MODEL TINY
CODESEG
RADIX 16
  12o
  12h
  12d
  101b
END
ASM

  is_deeply(
    $root->{segments}->[0]->{statements},
    [
      { literal => { kind => 'octal',   value => '12o'  } },
      { literal => { kind => 'hex',     value => '12h'  } },
      { literal => { kind => 'decimal', value => '12d'  } },
      { literal => { kind => 'binary',  value => '101b' } },
    ],
    'explicit suffixes preserve their numeric kind',
  );
};

subtest 'RADIX changes subsequent numeric values in source order' => sub {
  my $root = Parser::HPC->new->from_string(<<'ASM');
MODEL TINY
CODESEG
RADIX 16
  100
RADIX 10
  100
RADIX 2
  100
RADIX 8
  100
END
ASM

  is_deeply(
    $root->{segments}->[0]->{statements},
    [
      { literal => { kind => 'hex',     value => '100h' } },
      { literal => { kind => 'decimal', value => '100'  } },
      { literal => { kind => 'binary',  value => '100b' } },
      { literal => { kind => 'octal',   value => '100o' } },
    ],
    'each RADIX applies to following unsuffixed integers',
  );
};

subtest 'non-decimal values use signed 36-bit conversion in EQU' => sub {
  my $root = Parser::HPC->new->from_string(<<'ASM');
MODEL TINY
DATASEG
RADIX 16
  MAX      EQU 7FFFFFFFF
  MIN      EQU 800000000
  NEGATIVE EQU FFFFFFFFF
  SMALLNEG EQU FFFFFFEDB
END
ASM

  my $definitions = $root->{segments}->[0]->{definitions};
  is( $definitions->[0]->{value}, 34359738367, 'largest positive value' );
  is( $definitions->[1]->{value}, -34359738368, 'sign bit is negative' );
  is( $definitions->[2]->{value}, -1, 'all bits set is -1' );
  is( $definitions->[3]->{value}, -293, 'two-complement hexadecimal value' );
};

done_testing;
