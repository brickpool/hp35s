use strict;
use warnings;

use Test::More;
use Test::Exception;
use Parser::HPC;

{
  package ParserTest;
  use parent 'Parser::HPC';
  sub parse { return shift->token_vector }
  $INC{'ParserTest.pm'} = 1;
}

use_ok 'ParserTest';

subtest 'vector token accepts two or three components' => sub {
  for my $source (
    '[1,2]',
    '[1,2,3]',
    '[-1,2]',
    '[1.2,-3.4]',
    '[1e2,-3e-1]',
  ) {
    my $parser = ParserTest->new();
    is( $parser->from_string("$source\n"), $source, "$source is accepted" );
  }
};

subtest 'vector token rejects unsupported arity and separators' => sub {
  for my $source ( '[1]', '[1,2,3,4]', '[1;2]', '[1, 2]' ) {
    my $parser = ParserTest->new();
    dies_ok { $parser->from_string("$source\n") } "$source is rejected";
  }
};

done_testing;
