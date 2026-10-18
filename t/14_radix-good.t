use strict;
use warnings;

use Test::More;
use Parser::HPC;
use lib 't/lib';
use FrontendTest qw( run_frontend );

subtest 'RADIX resolves unsuffixed integers in source order' => sub {
  my $parser = Parser::HPC->new;
  my $root = $parser->from_string(<<'ASM');
IDEAL
P35S
MODEL TINY
CODESEG
RADIX 16 ; inline comment belongs to trailing trivia
  100
  1E7
  19B
  129d
  101b
RADIX 10
  100
RADIX 2
  100
RADIX 8
  100
RADIX 16
  12o
  12h
  12d
  2.3
  7e-1
END
ASM
  my $statements = $root->{segments}->[0]->{statements};
  is_deeply( $statements, [ map { +{ literal => $_ } } (
    { kind => 'hex', value => '100h' },
    { kind => 'hex', value => '1E7h' },
    { kind => 'hex', value => '19Bh' },
    { kind => 'decimal', value => '129d' },
    { kind => 'binary', value => '101b' },
    { kind => 'decimal', value => '100' },
    { kind => 'binary', value => '100b' },
    { kind => 'octal', value => '100o' },
    { kind => 'octal', value => '12o' },
    { kind => 'hex', value => '12h' },
    { kind => 'decimal', value => '12d' },
    { kind => 'decimal', value => '2.3' },
    { kind => 'decimal', value => 0.7 },
  ) ], 'active radix selects the kind and explicit suffixes take precedence' );
};

subtest 'RADIX applies to EQU, not instruction operands' => sub {
  my $parser = Parser::HPC->new;
  my $root = $parser->from_string(<<'ASM');
IDEAL
P35S
MODEL TINY
RADIX 16
DATASEG
  VALUE   EQU 100
  SUFFIXB EQU 101b
  SUFFIXO EQU 17o
  SUFFIXD EQU 12d
  SUFFIXH EQU FFh
RADIX 10
  FLOATVAL EQU 7e-1
RADIX 2
  OTHER EQU 100
CODESEG
start:
RADIX 2
  CF 11
RADIX 16
  FIX 11
  SF 10
  GTO start
END start
ASM
  is( $root->{segments}->[0]->{definitions}->[0]->{value}, 256,
    'EQU uses the active radix' );
  is( $root->{segments}->[0]->{definitions}->[1]->{value}, '101b',
    'suffixed binary EQU is preserved' );
  is( $root->{segments}->[0]->{definitions}->[2]->{value}, '17o',
    'suffixed octal EQU is preserved' );
  is( $root->{segments}->[0]->{definitions}->[3]->{value}, '12d',
    'suffixed decimal EQU is preserved' );
  is( $root->{segments}->[0]->{definitions}->[4]->{value}, 'FFh',
    'suffixed hexadecimal EQU is preserved' );
  is( $root->{segments}->[0]->{definitions}->[6]->{value}, 4,
    'RADIX inside data changes subsequent definitions' );
  cmp_ok( abs( $root->{segments}->[0]->{definitions}->[5]->{value} - 0.7 ),
    '<', 1e-12, 'lowercase e float converts under RADIX 10' );
  is( $root->{segments}->[1]->{statements}->[1]->{instruction}->{operand}->{value},
    11, 'CF operand remains decimal under RADIX 2' );
  is( $root->{segments}->[1]->{statements}->[2]->{instruction}->{operand}->{value},
    11, 'FIX operand remains decimal under RADIX 16' );
  is( $root->{segments}->[1]->{statements}->[3]->{instruction}->{operand}->{value},
    10, 'SF operand remains decimal under RADIX 16' );
  is_deeply( $root->{segments}->[1]->{statements}->[0],
    { label => { name => 'START' } }, 'RADIX preserves label declarations' );
  my $next = $parser->from_string("IDEAL\nP35S\nMODEL TINY\nCODESEG\n100\n\nEND\n");
  is_deeply( $next->{segments}->[0]->{statements}->[0],
    { literal => { kind => 'hex', value => '100h' } },
    'radix persists when the parser instance is reused' );
  my $fresh = Parser::HPC->new->from_string(
    "IDEAL\nP35S\nMODEL TINY\nCODESEG\n100\n\nEND\n"
  );
  is_deeply( $fresh->{segments}->[0]->{statements}->[0],
    { literal => { kind => 'decimal', value => '100' } },
    'a new parser instance starts in decimal' );
};

subtest 'non-decimal numeric values use signed 36-bit conversion' => sub {
  my $root = Parser::HPC->new->from_string(<<'ASM');
IDEAL
P35S
MODEL TINY
DATASEG
RADIX 16
  MAX       EQU 7FFFFFFFF
  MIN       EQU 800000000
  NEGATIVE  EQU FFFFFFFFF
  SMALLNEG  EQU FFFFFFEDB
END
ASM
  my $definitions = $root->{segments}->[0]->{definitions};
  is( $definitions->[0]->{value}, 34359738367, 'largest positive value' );
  is( $definitions->[1]->{value}, -34359738368, 'sign bit is negative' );
  is( $definitions->[2]->{value}, -1, 'all bits set is -1' );
  is( $definitions->[3]->{value}, -293,
    'two\'s-complement hexadecimal value' );
};

subtest 'RADIX listings match explicit suffixes without changing operands' => sub {
  my $source = <<'ASM';
IDEAL
P35S
MODEL TINY
RADIX 16
CODESEG
  LBL A
start:
RADIX 16
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
IDEAL
P35S
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
    my ($explicit_status, $expected, $explicit_errors) =
      run_frontend($explicit, @$options);
    is( $status, 0, 'RADIX source assembles' );
    is( $errors, '', 'RADIX produces no warnings' );
    is( $explicit_status, 0, 'explicit reference assembles' );
    is( $explicit_errors, '', 'reference produces no warnings' );
    is( $output, $expected,
      'output equals explicit suffixes: ' . join(' ', @$options) );
    like( $output, qr/GTO A002/, 'RADIX does not shift jump targets' );
  }
};

subtest 'display RADIX instructions are independent of the directive' => sub {
  for my $base ( 2, 8, 10, 16 ) {
    my $source = <<ASM;
IDEAL
P35S
MODEL TINY
CODESEG
LBL A
RADIX $base
start:
  RADIX. ; decimal point
  100
  RADIX, ; decimal comma
  100
RADIX 10
  100
  GTO start
  RTN
END start
ASM
    my %kinds = ( 2 => 'binary', 8 => 'octal', 10 => 'decimal', 16 => 'hex' );
    my %suffixes = ( 2 => 'b', 8 => 'o', 10 => '', 16 => 'h' );
    my $value = '100' . $suffixes{$base};
    my $root = Parser::HPC->new->from_string($source);
    is_deeply( $root->{segments}->[0]->{statements}, [
      { instruction => { value => 'LBL', operand => { type => 'variable', value => 'A' } } },
      { label => { name => 'START' } },
      { instruction => { value => 'RADIX.' } },
      { literal => { kind => $kinds{$base}, value => $value } },
      { instruction => { value => 'RADIX,' } },
      { literal => { kind => $kinds{$base}, value => $value } },
      { literal => { kind => 'decimal', value => '100' } },
      { instruction => { value => 'GTO', operand => { type => 'label', value => 'START' } } },
      { instruction => { value => 'RTN' } },
    ], "display instructions preserve parser base $base" );
    is_deeply( $root->{segments}->[0]->{statements}->[1],
      { label => { name => 'START' } },
      'declaration precedes the display instruction without RADIX directive nodes' );

    my ($status, $output, $errors) = run_frontend($source, '-s');
    is( $status, 0, "mixed source assembles in base $base" );
    is( $errors, '', 'no warnings' );
    my $point = "A002\tRADIX.\t\t; " . '\\<+ DISPLAY 5';
    my $comma = "A004\tRADIX,\t\t; " . '\\<+ DISPLAY 6';
    like( $output, qr/^\Q$point\E$/m,
      'decimal point retains its display keystrokes' );
    like( $output, qr/^\Q$comma\E$/m,
      'decimal comma retains its display keystrokes' );
    like( $output, qr/^A003\t\Q$value\E\t/m,
      'literal after RADIX. retains its base' );
    like( $output, qr/^A005\t\Q$value\E\t/m,
      'literal after RADIX, retains its base' );
    like( $output, qr/^A007\tGTO A002\t/m,
      'jump targets the display instruction' );
  }
};

subtest 'RADIX directive spelling is case-insensitive' => sub {
  for my $directive ( 'radix 16', 'Radix 16', 'RaDiX 16' ) {
    for my $source (
      "IDEAL\nP35S\nMODEL TINY\n$directive\nCODESEG\nRTN\n\nEND\n",
      "IDEAL\nP35S\nMODEL TINY\nCODESEG\n$directive\nRTN\n\nEND\n",
      "IDEAL\nP35S\nMODEL TINY\nDATASEG\n$directive\nVALUE EQU 1\n\nEND\n",
      "IDEAL\nP35S\nMODEL TINY\nSTACK\nREGX SET 1\n$directive\nCODESEG\nRTN\n\nEND\n",
    ) {
      my $success = eval { Parser::HPC->new->from_string($source); 1 };
      ok( $success, "$directive is allowed" );
    }
  }
};

done_testing;
