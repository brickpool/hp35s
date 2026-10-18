use strict;
use warnings;

use Test::More;
use lib 't/lib';
use FrontendTest qw( run_frontend );

subtest 'forward labels resolve before output generation' => sub {
  my $program = <<'ASM';
IDEAL
P35S
MODEL TINY
SEGMENT main CODE
start:
  LBL A
  GTO later
  XEQ value
  GTO second

later:
alias:
  RPN
  GTO start
value:
  0 ; a literal is also a valid jump target
second:
  LBL B
  XEQ alias
  RTN
ENDS main
END start
ASM
  my @listing = (
    [ 'A001', 'LBL A' ],
    [ 'A002', 'GTO A005' ],
    [ 'A003', 'XEQ A007' ],
    [ 'A004', 'GTO B001' ],
    [ 'A005', 'RPN' ],
    [ 'A006', 'GTO A001' ],
    [ 'A007', '0' ],
    [ 'B001', 'LBL B' ],
    [ 'B002', 'XEQ A005' ],
    [ 'B003', 'RTN' ],
  );
  my $listing = "%%HP: T(3)A(D)F(.);\n"
    . join('', map { join("\t", @$_) . "\n" } @listing);

  for my $mode ( '', '-j' ) {
    my @options = $mode ? ($mode) : ();
    my ($status, $output, $errors) = run_frontend($program, @options);
    my $expected_listing = $listing;
    $expected_listing =~ s/^(A001|A005|A007|B001)\t/$1*\t/gm if $mode;
    is( $status, 0, "forward labels succeed in mode '$mode'" );
    is( $errors, '', 'no unresolved targets or warnings' );
    is( $output, $expected_listing,
      'forward and backward targets, aliases and LBL resets retain their addresses' );
  }
};

subtest 'label references resolve across code segments' => sub {
  my $program = <<'ASM';
IDEAL
P35S
MODEL TINY
SEGMENT zulu CODE
later:
alias:
LBL B
XEQ start
RTN
ENDS zulu
SEGMENT alpha CODE
start:
LBL A
GTO later
XEQ alias
RTN
ENDS alpha
END start
ASM
  my $expected = "%%HP: T(3)A(D)F(.);\n"
    . "A001\tLBL A\nA002\tGTO B001\nA003\tXEQ B001\nA004\tRTN\n"
    . "B001\tLBL B\nB002\tXEQ A001\nB003\tRTN\n";
  for my $options ( [], [ '-j' ], [ '-s' ] ) {
    my ($status, $output, $errors) = run_frontend($program, @$options);
    is( $status, 0, 'frontend succeeds' );
    is( $errors, '', 'all segment targets resolve' );
    if ( @$options && $options->[0] eq '-s' ) {
      like( $output, qr/^A002\tGTO B001\t; GTO B ENTER$/m,
        'shortcut resolves the forward segment target' );
      like( $output, qr/^B002\tXEQ A001\t; XEQ A ENTER$/m,
        'shortcut resolves the backward segment target' );
    } else {
      my $listing = $expected;
      $listing =~ s/^(A001|B001)\t/$1*\t/gm if @$options;
      is( $output, $listing, 'aliases and segment targets use computed addresses' );
    }
  }
};

done_testing;