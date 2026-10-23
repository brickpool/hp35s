use strict;
use warnings;

use Test::More;
use Test::Exception;
use Parser::HPC;

{
  package ParserTest;
  use parent 'Parser::HPC';
  sub parse { return shift->token_string }
  $INC{'ParserTest.pm'} = 1;
}

use_ok 'ParserTest';

subtest 'string token accepts both delimiters' => sub {
  for my $case (
    [ '"I/O Library"', 'I/O Library' ],
    [ "'A+B'",         'A+B'         ],
  ) {
    my ($source, $expected) = @$case;
    my $parser = ParserTest->new();

    is( $parser->from_string("$source\n"), $expected, "$source is parsed" );
  }
};

subtest 'string token accepts an empty string' => sub {
  for my $source ( q{""}, q{''} ) {
    my $parser = ParserTest->new();
    is( $parser->from_string("$source\n"), '', "$source is parsed" );
  }
};

subtest 'string token preserves symbolic escapes' => sub {
  my $parser = ParserTest->new();
  is( $parser->from_string('"A\\"B"' . "\n"), 'A\\"B',
    'escaped delimiter is retained' );
};

subtest 'string token requires a delimiter' => sub {
  my $parser = ParserTest->new();

  throws_ok {
    $parser->from_string("text\n");
  } qr/Expected string delimiter/,
    'unquoted text is rejected';

  is( $@->{pos}, 0, 'failure position' );
};

subtest 'string token requires contents ending in the delimiter' => sub {
  my $parser = ParserTest->new();

  throws_ok {
    $parser->from_string('"text' . "\n");
  } qr/Expected contents of string/,
    'missing closing delimiter is rejected';

  is( $@->{pos}, 0, 'failure position' );
};

done_testing;
