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
    return shift->any_of( 'parse_macro_header' );
  }

  $INC{'ParserTest.pm'} = 1;
}

use_ok 'ParserTest';

subtest 'macro header is parsed' => sub {
  my $parser = ParserTest->new();

  is_deeply(
    $parser->from_string("MACRO test\n"),
    {
      TEST => {
        arguments => [],
      },
    },
    'macro without arguments',
  );

  is_deeply(
    $parser->from_string("MACRO test first, second, Third\n"),
    {
      TEST => {
        arguments => [qw(FIRST SECOND THIRD)],
      },
    },
    'macro with arguments',
  );
};

subtest 'macro arguments are case-insensitive' => sub {
  my $parser = ParserTest->new();

  throws_ok {
    $parser->from_string("MACRO test first, FIRST\n");
  } qr/Duplicate dummy argument: FIRST/,
    'duplicate dummy argument';
};

subtest 'invalid macro arguments are rejected' => sub {
  my $parser = ParserTest->new();

  throws_ok {
    $parser->from_string("MACRO test first,\n");
  } qr/Illegal macro argument/,
    'missing argument after comma';

  throws_ok {
    $parser->from_string("MACRO test first second\n");
  } qr/Extra characters/,
    'missing comma between arguments';
};

subtest 'macro name is required' => sub {
  my $parser = ParserTest->new();

  throws_ok {
    $parser->from_string("MACRO \n");
  } qr/Missing macro ID/,
    'missing macro name';
};

subtest 'malformed argument lists' => sub {
  my $parser = ParserTest->new();

  throws_ok {
    $parser->from_string("MACRO test ,first\n");
  } qr/Extra characters/,
    'missing first argument';

  throws_ok {
    $parser->from_string("MACRO test first,,second\n");
  } qr/Illegal macro argument/,
    'missing argument between commas';
};

subtest 'macro header does not continue on next line' => sub {
  my $parser = ParserTest->new();

  throws_ok {
    $parser->from_string("MACRO name arg1,\narg2\n");
  } qr/Illegal macro argument/,
    'argument list cannot continue after comma';

  throws_ok {
    $parser->from_string("MACRO\nname\n");
  } qr/Missing macro ID/,
    'macro name must be on MACRO line';

  throws_ok {
    $parser->from_string("MACRO name\narg\n");
  } qr/Expected end of input/,
    'following line is not part of macro header';

  is(
    $@->{pos},
    index($parser->{str}, 'arg'),
    'failure position points to following line',
  );
};

done_testing;
