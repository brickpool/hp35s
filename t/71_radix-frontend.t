use strict;
use warnings;

use Test::More;

use lib 't/lib';
use FrontendTest qw( run_frontend );

subtest 'RADIX listing matches explicit numeric suffixes' => sub {
  my $source = <<'ASM';
MODEL TINY
RADIX 16
CODESEG
  LBL A
start:
  100
  129d
  101b
RADIX 10
  100
RADIX 2
  100
  CF 11
RADIX 8
  100o
  GTO start
  RTN
END start
ASM

  my $explicit = <<'ASM';
MODEL TINY
CODESEG
  LBL A
start:
  100h
  129d
  101b
  100
  100b
  CF 11
  100o
  GTO start
  RTN
END start
ASM

  for my $options ( [], [ '-s' ], [ '-j' ] ) {
    my ($status, $output, $errors) = run_frontend($source, @$options);
    my ($expected_status, $expected, $expected_errors) =
      run_frontend($explicit, @$options);

    is( $status, 0, 'RADIX source assembles' );
    is( $errors, '', 'RADIX source has no warnings' );
    is( $expected_status, 0, 'explicit reference assembles' );
    is( $expected_errors, '', 'explicit reference has no warnings' );
    is( $output, $expected,
      'output equals explicit suffixes: ' . join(' ', @$options) );
    like( $output, qr/GTO A002/, 'RADIX does not shift jump targets' );
  }
};

subtest 'RADIX display instructions are independent of the directive' => sub {
  for my $base ( 2, 8, 10, 16 ) {
    my %suffixes = ( 2 => 'b', 8 => 'o', 10 => '', 16 => 'h' );
    my $value = '100' . $suffixes{$base};
    my $source = <<ASM;
MODEL TINY
CODESEG
LBL A
RADIX $base
start:
  RADIX.
  100
  RADIX,
  100
RADIX 10
  100
  GTO start
  RTN
END start
ASM

    my ($status, $output, $errors) = run_frontend($source, '-s');
    is( $status, 0, "source assembles in base $base" );
    is( $errors, '', 'no warnings' );
    like( $output, qr/^A002\tRADIX\.\t\t; \\\<(?:\+ )?DISPLAY 5$/m,
      'RADIX. retains its display keystrokes' );
    like( $output, qr/^A004\tRADIX,\t\t; \\\<(?:\+ )?DISPLAY 6$/m,
      'RADIX, retains its display keystrokes' );
    like( $output, qr/^A003\t\Q$value\E\t/m,
      'literal after RADIX. retains its base' );
    like( $output, qr/^A005\t\Q$value\E\t/m,
      'literal after RADIX, retains its base' );
    like( $output, qr/^A007\tGTO A002\t/m,
      'jump targets the display instruction' );
  }
};

done_testing;
