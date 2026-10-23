use strict;
use warnings;

use Test::More;
use Test::Exception;
use Parser::HPC;

{
  package ParserTest;
  use parent 'Parser::HPC';

  sub parse {
    my $self = shift;
    return $self->any_of(
      sub {
        $self->commit;
        return $self->parse_data_definition;
      },
    );
  }

  $INC{'ParserTest.pm'} = 1;
}

use_ok 'ParserTest';

subtest 'EQU defines numeric equations' => sub {
  for my $case (
    [ 'COUNT EQU 2',     2     ],
    [ 'NEG EQU -2',     -2     ],
    [ 'VALUE1 EQU 12d', '12d' ],
    [ 'VALUE2 EQU 17h', '17h' ],
    [ 'VALUE3 EQU 11b', '11b' ],
  ) {
    my ($source, $value) = @$case;
    my $name = (split /\s+/, $source)[0];
    my $parser = ParserTest->new();

    is_deeply(
      $parser->from_string("$source\n"),
      { name => $name, type => 'equation', value => $value },
      $source,
    );

    is(
      $parser->{symbols}->{$name},
      'equation',
      "$name enters the symbol table",
    );
  }
};

subtest 'EQU defines quoted strings' => sub {
  my $parser = ParserTest->new();

  is_deeply(
    $parser->from_string("FORMULA EQU 'A+B'\n"),
    { name => 'FORMULA', type => 'equation', value => 'A+B' },
    'quoted string value',
  );
  is(
    $parser->{symbols}->{FORMULA},
    'equation', 
    'FORMULA enters the symbol table'
  );
};

subtest 'EQU is case-insensitive' => sub {
  for my $source ( 'VALUE equ 2', 'Value Equ 2', 'value eQu 2' ) {
    my $parser = ParserTest->new();

    is_deeply(
      $parser->from_string("$source\n"),
      { name => 'VALUE', type => 'equation', value => 2 },
      "$source is accepted",
    );
  }
};

subtest 'definition names preserve their spelling' => sub {
  my $parser = ParserTest->new();

  is_deeply(
    $parser->from_string("eqnZulu EQU 'A+B'\n"),
    { name => 'EQNZULU', type => 'equation', value => 'A+B' },
    'identifier spelling is preserved',
  );
  is(
    $parser->{symbols}->{EQNZULU},
    'equation',
    'symbol table uses the parsed spelling'
  );
};

subtest 'definition rejects an empty quoted string' => sub {
  my $parser = ParserTest->new();

  throws_ok {
    $parser->from_string("EMPTY EQU \"\"\n");
  } qr/Need expression/,
    'empty quoted string is rejected';
};

subtest 'definition rejects an existing equation symbol' => sub {
  my $source = "VALUE EQU 2\n";
  my $parser = ParserTest->new();
  $parser->{symbols}->{VALUE} = 'equation';

  throws_ok {
    $parser->from_string($source);
  } qr/Symbol already defined/,
    'duplicate equation is rejected';

  is( $@->{pos}, index($source, 'VALUE'), 'failure position' );
};

subtest 'definition rejects a symbol of another kind' => sub {
  my $source = "REGX EQU 2\n";
  my $parser = ParserTest->new();

  throws_ok {
    $parser->from_string($source);
  } qr/Symbol already different kind/,
    'existing register symbol is rejected';

  is( $@->{pos}, index($source, 'REGX'), 'failure position' );
};

subtest 'definition requires EQU' => sub {
  my $source = "VALUE 2\n";
  my $parser = ParserTest->new();

  throws_ok {
    $parser->from_string($source);
  } qr/Expected .*EQU/,
    'missing EQU is rejected';

  is( $@->{pos}, index($source, '2'), 'failure position' );
};

subtest 'definition requires a value' => sub {
  my $source = "VALUE EQU \n; comment";
  my $parser = ParserTest->new();

  throws_ok {
    $parser->from_string($source);
  } qr/Need expression/,
    'missing value is rejected';

  is( $@->{pos}, length('VALUE EQU'), 'failure position' );
};

subtest 'definition rejects an empty quoted string' => sub {
  my $source = "EMPTY EQU ''\n";
  my $parser = ParserTest->new();

  throws_ok {
    $parser->from_string($source);
  } qr/Need expression|Need quoted string/,
    'empty quoted string is rejected';
};

subtest 'definition rejects trailing characters' => sub {
  my $source = "VALUE EQU 2 extra\n";
  my $parser = ParserTest->new();

  throws_ok {
    $parser->from_string($source);
  } qr/Extra characters/,
    'trailing characters are rejected';

  is( $@->{pos}, index($source, 'extra'), 'failure position' );
};

done_testing;
