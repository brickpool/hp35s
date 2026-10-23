use strict;
use warnings;

use Test::More;
use Test::Exception;
use Parser::HPC;

{
  package ParserTest;
  use parent 'Parser::HPC';
  sub parse {
    return shift->any_of('parse_stack_assignment');
  }
  $INC{'ParserTest.pm'} = 1;
}

use_ok 'ParserTest';

subtest 'SET assigns values to stack registers' => sub {
  for my $register ( qw(REGX REGY REGZ REGT) ) {
    my $parser = ParserTest->new();

    is_deeply(
      $parser->from_string("$register SET 2\n"),
      { $register => { type => 'register', value => 2 } },
      "$register SET 2",
    );
  }
};

subtest 'register and SET keywords are case-insensitive' => sub {
  for my $case (
    [ 'regx set 2', 'REGX' ],
    [ 'RegY Set 2', 'REGY' ],
    [ 'REGz sEt 2', 'REGZ' ],
    [ 'regT SET 2', 'REGT' ],
  ) {
    my ($source, $register) = @$case;
    my $parser = ParserTest->new();

    is_deeply(
      $parser->from_string("$source\n"),
      { $register => { type => 'register', value => 2 } },
      "$source is accepted",
    );
  }
};

subtest 'SET uses token_number for its value' => sub {
  for my $case (
    [ 'REGX SET -2',  -2    ],
    [ 'REGY SET 12d', '12d' ],
    [ 'REGZ SET 17h', '17h' ],
    [ 'REGT SET 11b', '11b' ],
  ) {
    my ($source, $value) = @$case;
    my $parser = ParserTest->new();

    is_deeply(
      $parser->from_string("$source\n"),
      { substr($source, 0, 4) => { type => 'register', value => $value } },
      $source,
    );
  }
};

subtest 'stack assignment requires SET' => sub {
  my $source = "REGX 2\n";
  my $parser = ParserTest->new();

  throws_ok {
    $parser->from_string($source);
  } qr/Expected .*SET/,
    'missing SET is rejected';

  is( $@->{pos}, index($source, '2'), 'failure position' );
};

subtest 'stack assignment requires a value' => sub {
  my $source = "REGX SET \n; comment";
  my $parser = ParserTest->new();

  throws_ok {
    $parser->from_string($source);
  } qr/Need expression/,
    'missing value is rejected';

  is( $@->{pos}, length('REGX SET'), 'failure position' );
};

subtest 'stack assignment rejects trailing characters' => sub {
  my $source = "REGX SET 2 extra\n";
  my $parser = ParserTest->new();

  throws_ok {
    $parser->from_string($source);
  } qr/Extra characters/,
    'trailing characters are rejected';

  is( $@->{pos}, index($source, 'extra'), 'failure position' );
};

done_testing;
