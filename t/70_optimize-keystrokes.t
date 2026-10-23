use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'HP35s::Keystrokes', qw(
    optimize_number_literal
    optimize_keystrokes
  );
}

subtest 'optimize indirect STO' => sub {
  my $input = '\+> STO \CC () \.> \BS RCL I () \BS \.>';
  my $expected = '\+> STO (I)';
  is( optimize_keystrokes($input), $expected, 'optimize indirect STO' );
  for ( 1 .. 25 ) {
    is( optimize_keystrokes($input), $expected, 'deterministic optimization', );
  }
};

subtest 'optimization does not get worse' => sub {
  my $in = '\+> STO \CC () \.> \BS RCL I () \BS \.>';
  my $out = optimize_keystrokes($in);
  ok( scalar( split /\s+/, $out ) <= scalar( split /\s+/, $in ),
    'optimization never increases keystrokes' );
};

subtest 'optimize number literals by keystroke count' => sub {
  for my $case (
    [ '1e-009', '1e-9' ],
    [ '1e+020', '1e20' ],
    [ '1000', '1e3' ],
    [ '3.0', '3' ],
    [ '0.0000012', '1.2e-6' ],
    [ '-0.5', '-.5' ],
    [ '12ABh', '12ABh' ],
  ) {
    is( optimize_number_literal($case->[0]), $case->[1],
      "$case->[0] becomes $case->[1]" );
  }
};

done_testing;
