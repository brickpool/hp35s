use strict;
use warnings;

use Test::More;
use Test::Exception;
use Parser::HPC;

{
  package ParserTest;
  use parent 'Parser::HPC';
  sub parse { return shift->token_kw_icase(qw(MODEL RADIX LOCALS)) }
  $INC{'ParserTest.pm'} = 1;
}

use_ok 'ParserTest';

subtest 'keyword token matches case-insensitively' => sub {
  for my $source ( qw(MODEL model Model RADIX radix LOCALS locals) ) {
    my $parser = ParserTest->new();
    is( 
      $parser->from_string("$source\n"), 
      $source,
      "$source is accepted and preserves its spelling"
    );
  }
};

subtest 'keyword token skips leading whitespace' => sub {
  my $parser = ParserTest->new();
  is(
    $parser->from_string("\t  MODEL\n"),
    'MODEL', 
    'leading whitespace is skipped'
  );
};

subtest 'keyword token rejects values outside the acceptable set' => sub {
  my $parser = ParserTest->new();

  throws_ok {
    $parser->from_string("DISPLAY\n");
  } qr/Expected any of MODEL, RADIX, LOCALS/,
    'unknown keyword is rejected';

  is( $@->{pos}, 0, 'failure position is reset' );
};

subtest 'keyword token requires a complete identifier' => sub {
  my $parser = ParserTest->new();

  throws_ok {
    $parser->from_string("MODELX\n");
  } qr/Expected any of MODEL, RADIX, LOCALS/,
    'keyword prefix is rejected';

  is( $@->{pos}, 0, 'failure position is reset' );
};

done_testing;
