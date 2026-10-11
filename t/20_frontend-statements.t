use strict;
use warnings;

use Test::More;
use lib 't/lib';
use FrontendTest qw( run_frontend );

my $source = <<'ASM';
MODEL P35S
SEGMENT DATA
  FORMULA EQU 'A+B'
ENDS
SEGMENT main CODE
start:
  LBL A
  RPN
value:
  0
  pi
  0110b
  7012o
  12ABh
  [1,2]
  [3,4,5]
  1i2
  3t4
  SIN
  REGX
  INPUT C
  STO (I)
  VIEW A
  FIX 0
  CF 11
  GTO A001
  XEQ value
  eqn 'A+B'
  eqn FORMULA
  LBL B
  GTO start
  RTN
  CLZ
ENDS main
END start
ASM

my @expected = (
  [ 'A001', 'LBL A' ],
  [ 'A002', 'RPN' ],
  [ 'A003', '0' ],
  [ 'A004', '\pi' ],
  [ 'A005', '0110b' ],
  [ 'A006', '7012o' ],
  [ 'A007', '12ABh' ],
  [ 'A008', '[1,2]' ],
  [ 'A009', '[3,4,5]' ],
  [ 'A010', '1\im2' ],
  [ 'A011', '3\Gh4' ],
  [ 'A012', 'SIN' ],
  [ 'A013', 'REGX' ],
  [ 'A014', 'INPUT C' ],
  [ 'A015', 'STO(I)' ],
  [ 'A016', 'VIEW A' ],
  [ 'A017', 'FIX 0' ],
  [ 'A018', 'CF 11' ],
  [ 'A019', 'GTO A001' ],
  [ 'A020', 'XEQ A003' ],
  [ 'A021', 'eqn A+B' ],
  [ 'A022', 'eqn A+B' ],
  [ 'B001', 'LBL B' ],
  [ 'B002', 'GTO A001' ],
  [ 'B003', 'RTN' ],
  [ 'B004', 'CL\\GS' ],
);
my $expected = "%%HP: T(3)A(D)F(.);\n"
  . join('', map { join("\t", @$_) . "\n" } @expected);

subtest 'new statement AST renders every kind and operand' => sub {
  my ($status, $output, $errors) = run_frontend($source);
  is( $status, 0, 'frontend succeeds' );
  is( $errors, '', 'no warnings' );
  is( $output, $expected,
    'listing preserves literals, operands, label resets and jump addresses' );
};

subtest 'jump markers resolve instruction and literal targets' => sub {
  my ($status, $output, $errors) = run_frontend($source, '-j');
  my $marked = $expected;
  $marked =~ s/^(A001|A003)\t/$1*\t/gm;
  is( $status, 0, 'frontend succeeds' );
  is( $errors, '', 'no warnings' );
  is( $output, $marked, 'both target nodes retain their line addresses' );
};

subtest 'decimal literals use the fewest numeric keystrokes' => sub {
  my $numbers = <<'ASM';
MODEL P35S
SEGMENT CODE
1e-9
1000
3.0
0.0000012
0.001
0.5
-0.5
ENDS
END
ASM
  my ($status, $output, $errors) = run_frontend($numbers, '-s');
  is( $status, 0, 'frontend succeeds' );
  is( $errors, '', 'no warnings' );
  like( $output, qr/^0001\t1e-9\t\t; 1 e \+\/- 9 ENTER$/m,
    'renders the optimized exponent used by the keystrokes' );
  like( $output, qr/^0002\t1e3\t\t; 1 e 3 ENTER$/m,
    'renders the optimized integer form used by the keystrokes' );
  like( $output, qr/^0003\t3\t\t; 3 ENTER$/m,
    'omits an unnecessary fractional zero in both render and keystrokes' );
  like( $output, qr/^0004\t1\.2e-6\t\t; 1 \. 2 e \+\/- 6 ENTER$/m,
    'renders the optimized small decimal used by the keystrokes' );
  like( $output, qr/^0005\t1e-3\t\t; 1 e \+\/- 3 ENTER$/m,
    'renders the optimized 0.001 value used by the keystrokes' );
  like( $output, qr/^0006\t0\.5\t\t; \. 5 ENTER$/m,
    'adds a leading zero only to the rendered fractional literal' );
  like( $output, qr/^0007\t-0\.5\t\t; \. 5 \+\/- ENTER$/m,
    'adds a leading zero to the rendered negative fraction only' );
};

subtest 'debug shows the parser statement AST without filtering' => sub {
  my ($status, $output, $errors) = run_frontend($source, '--debug');
  is( $status, 0, 'frontend succeeds' );
  is( $output, $expected, 'debug does not change the listing' );
  like( $errors, qr/'instruction'\s*=>/, 'instruction nodes retained' );
  like( $errors, qr/'literal'\s*=>/, 'literal nodes retained' );
  like( $errors, qr/'operand'\s*=>/, 'operands retained' );
  unlike( $errors, qr/'(?:LBL|0|pi)'\s*=>/, 'parser emits no legacy statement keys' );
  unlike( $errors, qr/'line'\s*=>/, 'debug still shows the AST before numbering' );
};

done_testing;