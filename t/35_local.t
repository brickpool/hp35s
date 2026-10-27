use strict;
use warnings;

use Test::More;
use Test::Exception;

use Parser::HPC;

{
  package ParserTest;
  use parent 'Parser::HPC';

  sub from_string {
    goto &Parser::MGC::from_string;
  }

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
      "$keyword is accepted",
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
    "LOCAL\n",
    "LOCAL \n",
    "LOCAL ; comment\n",
    "LOCAL 123\n",
  ) {
    my $parser = ParserTest->new();

    throws_ok {
      $parser->from_string($source);
    } qr/Illegal local argument/,
      "$source is rejected";
  }
};

subtest 'malformed LOCAL lists are rejected' => sub {
  my $parser = ParserTest->new();

  throws_ok {
    $parser->from_string("LOCAL again,\n");
  } qr/Illegal local argument/,
    'missing argument after comma';

  $parser = ParserTest->new();
  
  throws_ok {
    $parser->from_string("LOCAL again,,retry\n");
  } qr/Illegal local argument/,
    'missing argument between commas';
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

done_testing;
