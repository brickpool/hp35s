use strict;
use warnings;

use Test::More;
use Test::Exception;
use Parser::HPC;

{
  package ParserTest;
  use parent 'Parser::HPC';
  sub parse {
    return shift->any_of('parse_locals');
  }
  $INC{'ParserTest.pm'} = 1;
}

use_ok 'ParserTest';

subtest 'LOCALS enables local labels' => sub {
  my $parser = ParserTest->new();
  is_deeply(
    $parser->from_string("LOCALS\n"),
    {
      directive => {
        type  => 'locals',
        value => 1,
      },
    },
    'LOCALS is accepted',
  );
  is( $parser->{locals}, 1, 'local labels are enabled' );
};

subtest 'NOLOCALS disables local labels' => sub {
  my $parser = ParserTest->new();
  is_deeply(
    $parser->from_string("NOLOCALS\n"),
    {
      directive => {
        type  => 'locals',
        value => 0,
      },
    },
    'NOLOCALS is accepted',
  );
  is( $parser->{locals}, 0, 'local labels are disabled' );
};

subtest 'LOCALS and NOLOCALS are case-insensitive' => sub {
  for my $case (
    [ 'locals',   1 ],
    [ 'Locals',   1 ],
    [ 'nolocals', 0 ],
    [ 'Nolocals', 0 ],
  ) {
    my ($directive, $value) = @$case;
    my $parser = ParserTest->new();

    is_deeply(
      $parser->from_string("$directive\n"),
      {
        directive => {
          type  => 'locals',
          value => $value,
        },
      },
      "$directive is accepted",
    );
  }
};

subtest 'LOCALS and NOLOCALS reject arguments' => sub {
  for my $directive ( 'LOCALS', 'NOLOCALS' ) {
    my $source = "$directive extra\n";
    my $parser = ParserTest->new();

    throws_ok {
      $parser->from_string($source);
    } qr/Extra characters/,
      "$directive rejects trailing characters";

    is( $@->{pos}, index($source, 'extra'), 'failure position' );
  }
};

done_testing;
