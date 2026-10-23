use strict;
use warnings;

use Test::More;
use Test::Exception;
use Parser::HPC;

{
  package ParserTest;
  use parent 'Parser::HPC';
  sub parse {
    return shift->any_of('parse_radix');
  }
  $INC{'ParserTest.pm'} = 1;
}

use_ok 'ParserTest';

subtest 'RADIX accepts supported bases' => sub {
  for my $base ( 2, 8, 10, 16 ) {
    my $parser = ParserTest->new();

    is_deeply(
      $parser->from_string("RADIX $base\n"),
      { radix => $base },
      "RADIX $base",
    );
    is( $parser->{radix}, $base, "base is set to $base" );
  }
};

subtest 'RADIX accepts horizontal whitespace' => sub {
  for my $source ( "RADIX 16\n", "RADIX\t16\n" ) {
    my $parser = ParserTest->new();

    is_deeply(
      $parser->from_string($source),
      { radix => 16 },
      $source =~ /\t/ ? 'tab delimiter' : 'space delimiter',
    );
  }
};

subtest 'RADIX is case-insensitive' => sub {
  for my $directive ( 'radix', 'Radix', 'RaDiX' ) {
    my $parser = ParserTest->new();

    is_deeply(
      $parser->from_string("$directive 16\n"),
      { radix => 16 },
      "$directive is accepted",
    );
  }
};

subtest 'RADIX requires a supported base' => sub {
  for my $base ( 0, 3, 7, 17, -2 ) {
    my $source = "RADIX $base\n";
    my $parser = ParserTest->new();

    throws_ok {
      $parser->from_string($source);
    } qr/Illegal radix/,
      "RADIX $base is rejected";

    is( $@->{pos}, index($source, "$base"), 'failure position' );
  }
};

subtest 'RADIX requires a base' => sub {
  my $source = "RADIX \n; comment";
  my $parser = ParserTest->new();

  throws_ok {
    $parser->from_string($source);
  } qr/Illegal radix/,
    'missing base';

  is( $@->{pos}, index($source, "\n") + 1, 'failure position' );
};

subtest 'RADIX rejects trailing characters' => sub {
  my $source = "RADIX 16 extra\n";
  my $parser = ParserTest->new();

  throws_ok {
    $parser->from_string($source);
  } qr/Extra characters/,
    'trailing characters';

  is( $@->{pos}, index($source, 'extra'), 'failure position' );
};

done_testing;
