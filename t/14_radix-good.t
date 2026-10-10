use strict;
use warnings;

use Test::More;
use Parser::HPC;
use lib 't/lib';
use FrontendTest qw( run_frontend );

subtest 'RADIX resolves unsuffixed integers in source order' => sub {
  my $parser = Parser::HPC->new;
  my $root = $parser->from_string(<<'ASM');
MODEL P35S
SEGMENT CODE
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
ENDS
END
ASM
  my $statements = $root->{segments}->{_TEXT}->{statements};
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

subtest 'RADIX applies to EQU and SET, not instruction operands' => sub {
  my $parser = Parser::HPC->new;
  my $root = $parser->from_string(<<'ASM');
MODEL P35S
RADIX 16
SEGMENT DATA
VALUE EQU 100
SUFFIXB EQU 101b
SUFFIXO EQU 17o
SUFFIXD EQU 12d
SUFFIXH EQU FFh
RADIX 10
FLOATVAL EQU 7e-1
RADIX 2
OTHER EQU 100
ENDS
SEGMENT STACK
REGX SET 100
RADIX 10
REGT SET 7e-1
RADIX 16
REGY SET 100
REGZ SET FFh
ENDS
SEGMENT CODE
start:
RADIX 2
CF 11
RADIX 16
FIX 11
SF 10
GTO start
ENDS
END start
ASM
  is( $root->{segments}->{_DATA}->{definitions}->{VALUE}->{value}, 256,
    'EQU uses the active radix' );
  is( $root->{segments}->{_DATA}->{definitions}->{SUFFIXB}->{value}, '101b',
    'suffixed binary EQU is preserved' );
  is( $root->{segments}->{_DATA}->{definitions}->{SUFFIXO}->{value}, '17o',
    'suffixed octal EQU is preserved' );
  is( $root->{segments}->{_DATA}->{definitions}->{SUFFIXD}->{value}, '12d',
    'suffixed decimal EQU is preserved' );
  is( $root->{segments}->{_DATA}->{definitions}->{SUFFIXH}->{value}, 'FFh',
    'suffixed hexadecimal EQU is preserved' );
  is( $root->{segments}->{_DATA}->{definitions}->{OTHER}->{value}, 4,
    'RADIX inside data changes subsequent definitions' );
  cmp_ok( abs( $root->{segments}->{_DATA}->{definitions}->{FLOATVAL}->{value} - 0.7 ),
    '<', 1e-12, 'lowercase e float converts under RADIX 10' );
  is( $root->{segments}->{STACK}->{assignments}->{REGX}->{value}, 4,
    'radix persists across segments' );
  is( $root->{segments}->{STACK}->{assignments}->{REGY}->{value}, 256,
    'RADIX works inside stack segments' );
  is( $root->{segments}->{STACK}->{assignments}->{REGZ}->{value}, 'FFh',
    'suffixed hexadecimal SET is preserved' );
  cmp_ok( abs( $root->{segments}->{STACK}->{assignments}->{REGT}->{value} - 0.7 ),
    '<', 1e-12, 'lowercase e float converts under RADIX 10' );
  is( $root->{segments}->{_TEXT}->{statements}->[0]->{instruction}->{operand}->{value},
    11, 'CF operand remains decimal under RADIX 2' );
  is( $root->{segments}->{_TEXT}->{statements}->[1]->{instruction}->{operand}->{value},
    11, 'FIX operand remains decimal under RADIX 16' );
  is( $root->{segments}->{_TEXT}->{statements}->[2]->{instruction}->{operand}->{value},
    10, 'SF operand remains decimal under RADIX 16' );
  is( $root->{labels}->{START}->{statement}, 0,
    'labels skip RADIX directives' );
  my $next = $parser->from_string("MODEL P35S\nSEGMENT next CODE\n100\nENDS next\nEND\n");
  is_deeply( $next->{segments}->{NEXT}->{statements}->[0],
    { literal => { kind => 'hex', value => '100h' } },
    'radix persists when the parser instance is reused' );
  my $fresh = Parser::HPC->new->from_string(
    "MODEL P35S\nSEGMENT CODE\n100\nENDS\nEND\n"
  );
  is_deeply( $fresh->{segments}->{_TEXT}->{statements}->[0],
    { literal => { kind => 'decimal', value => '100' } },
    'a new parser instance starts in decimal' );
};

subtest 'non-decimal numeric values use signed 36-bit conversion' => sub {
  my $root = Parser::HPC->new->from_string(<<'ASM');
MODEL P35S
SEGMENT DATA
RADIX 16
MAX EQU 7FFFFFFFF
MIN EQU 800000000
NEGATIVE EQU FFFFFFFFF
SMALLNEG EQU FFFFFFEDB
ENDS
END
ASM
  my $definitions = $root->{segments}->{_DATA}->{definitions};
  is( $definitions->{MAX}->{value}, 34359738367, 'largest positive value' );
  is( $definitions->{MIN}->{value}, -34359738368, 'sign bit is negative' );
  is( $definitions->{NEGATIVE}->{value}, -1, 'all bits set is -1' );
  is( $definitions->{SMALLNEG}->{value}, -293,
    'two\'s-complement hexadecimal value' );
};

subtest 'RADIX listings match explicit suffixes without changing operands' => sub {
  my $source = <<'ASM';
MODEL P35S
RADIX 16
SEGMENT CODE
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
ENDS
END start
ASM
  my $explicit = <<'ASM';
MODEL P35S
SEGMENT CODE
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
ENDS
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
MODEL P35S
SEGMENT CODE
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
ENDS
END start
ASM
    my %kinds = ( 2 => 'binary', 8 => 'octal', 10 => 'decimal', 16 => 'hex' );
    my %suffixes = ( 2 => 'b', 8 => 'o', 10 => '', 16 => 'h' );
    my $value = '100' . $suffixes{$base};
    my $root = Parser::HPC->new->from_string($source);
    is_deeply( $root->{segments}->{_TEXT}->{statements}, [
      { instruction => { value => 'LBL', operand => { type => 'variable', value => 'A' } } },
      { instruction => { value => 'RADIX.' } },
      { literal => { kind => $kinds{$base}, value => $value } },
      { instruction => { value => 'RADIX,' } },
      { literal => { kind => $kinds{$base}, value => $value } },
      { literal => { kind => 'decimal', value => '100' } },
      { instruction => { value => 'GTO', operand => { type => 'label', value => 'START' } } },
      { instruction => { value => 'RTN' } },
    ], "display instructions preserve parser base $base" );
    is( $root->{labels}->{START}->{statement}, 1,
      'display instruction is a label target; directive is not a statement' );

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

done_testing;
