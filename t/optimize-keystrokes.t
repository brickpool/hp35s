use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'HP35S::Encode::Keystrokes', qw( optimize_keystrokes );
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

done_testing;
