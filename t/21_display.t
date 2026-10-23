use strict;
use warnings;

use Test::More;
use Test::Exception;
use Parser::HPC;

{
  package ParserTest;
  use parent 'Parser::HPC';
  sub parse {
    return shift->any_of('parse_display');
  }
  $INC{'ParserTest.pm'} = 1;
}

use_ok 'ParserTest';

subtest 'DISPLAY parses a quoted message' => sub {
  my $parser = ParserTest->new();
  my @warnings;

  {
    local $SIG{__WARN__} = sub { push @warnings, @_ };

    is_deeply(
      $parser->from_string("DISPLAY \"Starting assembly\"\n"),
      { display => 'Starting assembly' },
      'quoted message',
    );
  }

  is( scalar @warnings, 1, 'one warning is emitted' );
  like( $warnings[0], qr/\AStarting assembly(?:\s|\z)/, 'message is warned' );
};

subtest 'DISPLAY accepts horizontal whitespace' => sub {
  for my $source (
    "DISPLAY \"message\"\n",
    "DISPLAY\t\"message\"\n",
  ) {
    my $parser = ParserTest->new();
    local $SIG{__WARN__} = sub { };

    is_deeply(
      $parser->from_string($source),
      { display => 'message' },
      $source =~ /\t/ ? 'tab delimiter' : 'space delimiter',
    );
  }
};

subtest 'DISPLAY is case-insensitive' => sub {
  for my $directive (
    'display',
    'Display',
    'DiSpLaY',
  ) {
    my $parser = ParserTest->new();
    local $SIG{__WARN__} = sub { };

    is_deeply(
      $parser->from_string("$directive \"message\"\n"),
      { display => 'message' },
      "$directive is accepted",
    );
  }
};

subtest 'DISPLAY requires a quoted string' => sub {
  my $source = "DISPLAY \n";
  my $parser = ParserTest->new();

  throws_ok {
    $parser->from_string($source);
  } qr/Need quoted string/,
    'missing quoted string';

  is( $@->{pos}, index($source, "\n"), 'failure position' );
};

subtest 'DISPLAY rejects an empty string' => sub {
  my $source = "DISPLAY ''\n";
  my $parser = ParserTest->new();

  throws_ok {
    $parser->from_string($source);
  } qr/Need quoted string/,
    'empty quoted string';

  is( $@->{pos}, index($source, "'"), 'failure position' );
};

subtest 'DISPLAY requires the closing quote on the same line' => sub {
  my $source = "DISPLAY \"I/O\nLibrary\"\n";
  my $parser = ParserTest->new();

  throws_ok {
    $parser->from_string($source);
  } qr/Missing end quote/,
    'newline inside quoted string';

  is( $@->{pos}, index($source, "\n"), 'failure position' );
};

subtest 'DISPLAY rejects trailing characters' => sub {
  my $source = "DISPLAY \"message\" extra\n";
  my $parser = ParserTest->new();
  my @warnings;

  {
    local $SIG{__WARN__} = sub { push @warnings, @_ };

    throws_ok {
      $parser->from_string($source);
    } qr/Extra characters/,
      'trailing characters';
  }

  is( $@->{pos}, index($source, 'extra'), 'failure position' );
  is_deeply( \@warnings, [], 'invalid DISPLAY emits no message' );
};

done_testing;