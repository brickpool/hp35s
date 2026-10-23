use strict;
use warnings;

use Test::More;
use Test::Exception;
use Parser::HPC;

{
  package ParserTest;
  use parent 'Parser::HPC';
  sub parse {
    return shift->any_of('parse_language');
  }
  $INC{'ParserTest.pm'} = 1;
}

use_ok 'ParserTest';

subtest 'LANGUAGE accepts supported language IDs' => sub {
  my $parser = ParserTest->new();

  is_deeply(
    $parser->from_string("P35S\n"),
    { language => 'P35S' },
    'P35S is accepted',
  );

  is( $parser->{language}, 'P35S', 'language is set to P35S' );
};

subtest 'LANGUAGE is case-insensitive' => sub {
  for my $language (
    'p35s',
    'P35s',
    'p35S',
  ) {
    my $parser = ParserTest->new();

    is_deeply(
      $parser->from_string("$language\n"),
      { language => 'P35S' },
      "$language is accepted",
    );
  }
};

subtest 'LANGUAGE rejects trailing characters' => sub {
  my $source = "P35S extra\n";
  my $parser = ParserTest->new();

  throws_ok {
    $parser->from_string($source);
  } qr/Extra characters/,
    'trailing characters';

  is( $@->{pos}, index($source, 'extra'), 'failure position' );
};

done_testing;
