use strict;
use warnings;

use Test::More;
use Test::Exception;
use Parser::HPC;

{
  package ParserTest;
  use parent 'Parser::HPC';
  sub parse {
    return shift->any_of('parse_mode');
  }
  $INC{'ParserTest.pm'} = 1;
}

use_ok 'ParserTest';

subtest 'MODE accepts supported modes' => sub {
  for my $mode ( 'IDEAL', 'MASM' ) {
    my $parser = ParserTest->new();

    is_deeply(
      $parser->from_string("$mode\n"),
      { mode => $mode },
      "$mode is accepted",
    );

    is( $parser->{mode}, $mode, "mode is set to $mode" );
  }
};

subtest 'MODE is case-insensitive' => sub {
  for my $source (
    "ideal\n",
    "Ideal\n",
    "mAsM\n",
  ) {
    my $parser = ParserTest->new();

    my $expected = uc $source;
    chomp $expected;

    is_deeply(
      $parser->from_string($source),
      { mode => $expected },
      "$expected is accepted",
    );
  }
};

subtest 'MODE rejects trailing characters' => sub {
  for my $mode ( 'IDEAL', 'MASM' ) {
    my $source = "$mode extra\n";
    my $parser = ParserTest->new();

    throws_ok {
      $parser->from_string($source);
    } qr/Extra characters/,
      "$mode rejects trailing characters";

    is( $@->{pos}, index($source, 'extra'), 'failure position' );
  }
};

done_testing;
