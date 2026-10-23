use strict;
use warnings;

use Test::More;
use Test::Exception;
use Parser::HPC;

{
  package ParserTest;
  use parent 'Parser::HPC';
  sub parse { 
    return shift->any_of('parse_title');
  }
  $INC{'ParserTest.pm'} = 1;
}

use_ok 'ParserTest';

subtest '%TITLE parses a quoted title' => sub {
  my $parser = ParserTest->new();

  is_deeply(
    $parser->from_string("%TITLE \"I/O Library\"\n"),
    { title => 'I/O Library' },
    'quoted title',
  );
};

subtest '%TITLE accepts horizontal whitespace' => sub {
  for my $source (
    "%TITLE \"I/O Library\"\n",
    "%TITLE\t\"I/O Library\"\n",
  ) {
    my $parser = ParserTest->new();

    is_deeply(
      $parser->from_string($source),
      { title => 'I/O Library' },
      $source =~ /\t/ ? 'tab delimiter' : 'space delimiter',
    );
  }
};

subtest '%TITLE is case-insensitive' => sub {
  for my $directive (
    '%title',
    '%Title',
    '%TiTlE',
  ) {
    my $parser = ParserTest->new();

    is_deeply(
      $parser->from_string("$directive \"I/O Library\"\n"),
      { title => 'I/O Library' },
      "$directive is accepted",
    );
  }
};

subtest '%TITLE requires a quoted string' => sub {
  my $source = "%TITLE \n";
  my $parser = ParserTest->new();

  throws_ok {
    $parser->from_string($source);
  } qr/Need quoted string/,
    'missing quoted string';

  is( $@->{pos}, index($source, "\n"), 'failure position' );
};

subtest '%TITLE requires the closing quote on the same line' => sub {
  my $source = "%TITLE \"I/O\nLibrary\"\n";
  my $parser = ParserTest->new();

  throws_ok {
    $parser->from_string($source);
  } qr/Missing end quote/,
    'newline inside quoted string';

  is( $@->{pos}, index($source, "\n"), 'failure position' );
};

subtest '%TITLE rejects trailing characters' => sub {
  my $source = "%TITLE \"I/O Library\" extra\n";
  my $parser = ParserTest->new();

  throws_ok {
    $parser->from_string($source);
  } qr/Extra characters/,
    'trailing characters';

  is( $@->{pos}, index($source, 'extra'), 'failure position' );
};

done_testing;
