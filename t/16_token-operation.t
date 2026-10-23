use strict;
use warnings;

use Test::More;
use Test::Exception;
use Parser::HPC;

{
  package ParserTest;
  use parent 'Parser::HPC';
  sub parse { return shift->token_kw_operation(qw(RTN GTO eqn RADIX.)) }
  $INC{'ParserTest.pm'} = 1;
}

use_ok 'ParserTest';

subtest 'operation token matches the exact vocabulary spelling' => sub {
  for my $source ( qw(RTN GTO eqn RADIX.) ) {
    my $parser = ParserTest->new();
    is( $parser->from_string("$source\n"), $source, "$source is accepted" );
  }
};

subtest 'operation token is case-sensitive' => sub {
  for my $source ( qw(rtn gto EQN radix.) ) {
    my $parser = ParserTest->new();

    throws_ok {
      $parser->from_string("$source\n");
    } qr/Expected any of RTN, GTO, eqn, RADIX\./,
      "$source is rejected";

    is( $@->{pos}, 0, 'failure position is reset' );
  }
};

subtest 'operation token stops at whitespace' => sub {
  my $parser = ParserTest->new();
  is( $parser->from_string("GTO\n"), 'GTO', 'operation ends at whitespace' );
};

subtest 'operation token rejects parentheses' => sub {
  my $parser = ParserTest->new();
  dies_ok { $parser->from_string("GTO(I)\n") }
    'parenthesized suffix is not part of the operation token';
};

done_testing;
