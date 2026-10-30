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
    my $self = shift;
    return $self->any_of('parse_macro_line');
  }

  $INC{'ParserTest.pm'} = 1;
}

use_ok 'ParserTest';

subtest 'macro source line is preserved' => sub {
  my $parser = ParserTest->new();

  is(
    $parser->from_string("  STO target\n"),
    'STO target',
    'leading whitespace is skipped',
  );
};

subtest 'trailing comment is removed' => sub {
  my $parser = ParserTest->new();

  is(
    $parser->from_string("  STO target  ;; comment\n"),
    'STO target',
    'comment and trailing whitespace are removed',
  );
};

subtest 'semicolon in quoted text is preserved' => sub {
  my $parser = ParserTest->new();

  is(
    $parser->from_string(qq{  DISPLAY "one; two" ; comment\n}),
    q{DISPLAY "one; two"},
    'semicolon in double-quoted text is preserved',
  );

  $parser = ParserTest->new();

  is(
    $parser->from_string(qq{  EQN 'A;B' ; comment\n}),
    q{EQN 'A;B'},
    'semicolon in single-quoted text is preserved',
  );
};

subtest 'multiple quoted sections are preserved' => sub {
  my $parser = ParserTest->new();

  is(
    $parser->from_string(
      qq{  DISPLAY "one; two" 'three; four' ; comment\n}
    ),
    q{DISPLAY "one; two" 'three; four'},
    'multiple quoted sections are preserved',
  );
};

subtest 'late LOCAL is rejected' => sub {
  my $parser = ParserTest->new();

  throws_ok {
    $parser->from_string("LOCAL again\n");
  } qr/Unexpected LOCAL in macro line/,
    'LOCAL is only allowed before macro body lines';
};

done_testing;
