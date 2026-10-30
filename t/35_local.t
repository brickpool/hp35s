use strict;
use warnings;

use Test::More;
use Test::Exception;

use Parser::HPC;

{
  package ParserTest;
  use parent 'Parser::HPC';

  sub parse {
    return shift->any_of( 'parse_local' );
  }

  $INC{'ParserTest.pm'} = 1;
}

use_ok 'ParserTest';

subtest 'LOCAL labels are parsed and canonicalized' => sub {
  my $parser = ParserTest->new();

  is_deeply(
    $parser->from_string("LOCAL again\n"),
    {
      locals => ['AGAIN'],
    },
    'single local label',
  );

  $parser = ParserTest->new();

  is_deeply(
    $parser->from_string("LOCAL again, retry, \@\@fallback\n"),
    {
      locals => [qw(AGAIN RETRY @@FALLBACK)],
    },
    'multiple local labels',
  );
};

subtest 'LOCAL is case-insensitive' => sub {
  for my $keyword (qw(LOCAL Local local)) {
    my $parser = ParserTest->new();

    is_deeply(
      $parser->from_string("$keyword again\n"),
      {
        locals => ['AGAIN'],
      },
      "'$keyword' is accepted",
    );
  }
};

subtest 'LOCAL arguments are case-insensitive' => sub {
  my $parser = ParserTest->new();

  is_deeply(
    $parser->from_string("LOCAL Again, RETRY, \@\@Fallback\n"),
    {
      locals => [qw(AGAIN RETRY @@FALLBACK)],
    },
    'local labels are canonicalized',
  );
};

subtest 'LOCAL requires an argument' => sub {
  for my $source (
    "LOCAL",
    "LOCAL ",
    "LOCAL ; comment",
    "LOCAL 123",
  ) {
    my $parser = ParserTest->new();

    throws_ok {
      $parser->from_string("$source\n");
    } qr/Illegal local argument/,
      "'$source' is rejected";
  }
};

subtest 'malformed LOCAL lists are rejected' => sub {
  for my $source (
    "LOCAL again,",
    "LOCAL again,,retry",
    "LOCAL name,123",
  ) {
    my $parser = ParserTest->new();

    throws_ok {
      $parser->from_string("$source\n");
    } qr/Illegal local argument/,
      "'$source' is rejected";
  }

  for my $source (
    "LOCAL name:WORD",
    "LOCAL name other",
  ) {
    my $parser = ParserTest->new();

    throws_ok {
      $parser->from_string("$source\n");
    } qr/Expected end of input/,
      "'$source' is rejected";
  }
};

subtest 'LOCAL does not continue on next line' => sub {
  my $parser = ParserTest->new();

  throws_ok {
    $parser->from_string("LOCAL again,\nretry\n");
  } qr/Illegal local argument/,
    'argument list cannot continue on next line';
};

subtest 'LOCAL collides with existing symbols case-insensitively' => sub {
  my $parser = ParserTest->new();

  $parser->{symbols}->{AGAIN} = 'label';

  throws_ok {
    $parser->from_string("LOCAL again\n");
  } qr/Symbol already different kind/,
    'existing label conflicts with LOCAL';

  $parser = ParserTest->new();

  $parser->{symbols}->{VALUE} = 'equation';

  throws_ok {
    $parser->from_string("LOCAL value\n");
  } qr/Symbol already different kind/,
    'existing equation conflicts with LOCAL';
};

subtest 'LOCAL rejects existing symbols' => sub {
  for my $name ('RTN', 'pi') {
    my $parser = ParserTest->new();

    throws_ok {
      $parser->from_string("LOCAL $name\n");
    } qr/Symbol already different kind/,
      "$name cannot be used as LOCAL";
  }
};

done_testing;
