use strict;
use warnings;

use Test::More;
use Test::Exception;
use Parser::HPC;

{
  package ParserTest;
  use parent 'Parser::HPC';
  sub parse { return shift->token_complex }
  $INC{'ParserTest.pm'} = 1;
}

use_ok 'ParserTest';

subtest 'complex token accepts rectangular and polar separators' => sub {
  for my $source ( '1i2', '-1i2', '1t2', '1.5i-2.5', '1e2t3e-1' ) {
    my $parser = ParserTest->new();
    is( $parser->from_string("$source\n"), $source, "$source is accepted" );
  }
};

subtest 'complex token rejects missing components and unknown separators' => sub {
  for my $source ( 'i2', '1i', '1j2', '1 i 2' ) {
    my $parser = ParserTest->new();
    dies_ok { $parser->from_string("$source\n") } "$source is rejected";
  }
};

done_testing;
