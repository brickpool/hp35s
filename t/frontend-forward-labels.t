use strict;
use warnings;

use Test::More;
use lib 't/lib';
use FrontendTest qw( run_frontend );

subtest 'forward labels resolve before output generation' => sub {
  my $program = <<'ASM';
MODEL P35S
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

done_testing;