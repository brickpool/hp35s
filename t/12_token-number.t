use strict;
use warnings;

use Test::More;
use Parser::HPC;

{
  package ParserTest;
  use parent 'Parser::HPC';
  sub parse { return shift->token_number }
  $INC{'ParserTest.pm'} = 1;
}

use_ok 'ParserTest';

subtest 'number token dispatches explicit numeric forms' => sub {
  for my $case (
    [ '101b', '101b' ],
    [ '12o',  '12o'  ],
    [ '12d',  '12d'  ],
    [ '17h',  '17h'  ],
    [ '2.5',  2.5    ],
    [ '7e-1', 0.7    ],
  ) {
    my ($source, $expected) = @$case;
    my $parser = ParserTest->new();

    is( $parser->from_string("$source\n"), $expected, "$source is parsed" );
  }
};

subtest 'number token applies the active radix to unsuffixed integers' => sub {
  for my $case (
    [ 2,  '100', 4   ],
    [ 8,  '100', 64  ],
    [ 10, '100', 100 ],
    [ 16, '100', 256 ],
  ) {
    my ($radix, $source, $expected) = @$case;
    my $parser = ParserTest->new();
    $parser->{radix} = $radix;

    is( $parser->from_string("$source\n"), $expected,
      "RADIX $radix converts $source" );
  }
};

subtest 'number token converts 36-bit signed values' => sub {
  for my $case (
    [ 16, '7FFFFFFFF',  34359738367  ],
    [ 16, '800000000', -34359738368  ],
    [ 16, 'FFFFFFFFF', -1            ],
  ) {
    my ($radix, $source, $expected) = @$case;
    my $parser = ParserTest->new();
    $parser->{radix} = $radix;

    is( $parser->from_string("$source\n"), $expected, "$source is signed" );
  }
};

done_testing;
