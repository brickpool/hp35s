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
        return $self->parse_code_instruction;
      },
    );
  }
  $INC{'ParserTest.pm'} = 1;
}

use_ok 'ParserTest';

subtest 'plain instruction has no operand' => sub {
  my $parser = ParserTest->new();

  is_deeply(
    $parser->from_string("RTN\n"),
    { instruction => { value => 'RTN' } },
    'RTN is parsed',
  );
};

subtest 'address instructions parse labels' => sub {
  for my $mnemonic ( qw(GTO XEQ) ) {
    my $parser = ParserTest->new();

    is_deeply(
      $parser->from_string("$mnemonic target\n"),
      {
        instruction => {
          value   => $mnemonic,
          operand => { type => 'label', value => 'TARGET' },
        },
      },
      "$mnemonic parses a label operand",
    );
  }
};

subtest 'address instructions distinguish calculator addresses' => sub {
  my $parser = ParserTest->new();

  is_deeply(
    $parser->from_string("GTO A001\n"),
    {
      instruction => {
        value   => 'GTO',
        operand => { type => 'address', value => 'A001' },
      },
    },
    'calculator address is retained as an address',
  );
};

subtest 'variable instructions parse register variables' => sub {
  my $parser = ParserTest->new();

  is_deeply(
    $parser->from_string("INPUT X\n"),
    {
      instruction => {
        value   => 'INPUT',
        operand => { type => 'variable', value => 'X' },
      },
    },
    'INPUT parses a variable operand',
  );
};

subtest 'digit instructions accept values from 0 to 11' => sub {
  for my $case (
    [ 'CF',  0  ],
    [ 'SF',  10 ],
    [ 'FIX', 11 ],
  ) {
    my ($mnemonic, $value) = @$case;
    my $parser = ParserTest->new();

    is_deeply(
      $parser->from_string("$mnemonic $value\n"),
      {
        instruction => {
          value   => $mnemonic,
          operand => { type => 'decimal', value => $value },
        },
      },
      "$mnemonic accepts $value",
    );
  }
};

subtest 'indirect instructions parse variables' => sub {
  for my $operand ( 'X', '(I)', '(J)' ) {
    my $parser = ParserTest->new();

    is_deeply(
      $parser->from_string("VIEW $operand\n"),
      {
        instruction => {
          value   => 'VIEW',
          operand => { type => 'variable', value => $operand },
        },
      },
      "VIEW accepts $operand",
    );
  }
};

subtest 'EQN parses quoted expressions' => sub {
  my $parser = ParserTest->new();

  is_deeply(
    $parser->from_string("eqn 'A+B'\n"),
    {
      instruction => {
        value   => 'eqn',
        operand => { type => 'expression', value => 'A+B' },
      },
    },
    'quoted expression is parsed',
  );
};

subtest 'EQN resolves known equations' => sub {
  my $parser = ParserTest->new();
  $parser->{symbols}->{FORMULA} = 'equation';

  is_deeply(
    $parser->from_string("eqn FORMULA\n"),
    {
      instruction => {
        value   => 'eqn',
        operand => { type => 'equation', value => 'FORMULA' },
      },
    },
    'known equation is parsed by name',
  );
};

subtest 'equation operand uses canonical symbol name' => sub {
  my $parser = ParserTest->new();
  $parser->{symbols}->{EQNMAIN} = 'equation';

  is_deeply(
    $parser->from_string("eqn eQnMaIn\n"),
    {
      instruction => {
        value   => 'eqn',
        operand => {
          type  => 'equation',
          value => 'EQNMAIN',
        },
      },
    },
    'equation reference is canonicalized',
  );
};

subtest 'expression operand preserves its contents' => sub {
  my $parser = ParserTest->new();

  is_deeply(
    $parser->from_string("eqn '2*pi'\n"),
    {
      instruction => {
        value   => 'eqn',
        operand => {
          type  => 'expression',
          value => '2*pi',
        },
      },
    },
    'expression contents are not canonicalized',
  );
};

subtest 'address instruction requires an operand' => sub {
  my $source = "GTO \n";
  my $parser = ParserTest->new();

  throws_ok {
    $parser->from_string($source);
  } qr/Illegal origin address/,
    'missing address is rejected';
};

subtest 'digit instruction requires a decimal operand' => sub {
  my $source = "CF \n";
  my $parser = ParserTest->new();

  throws_ok {
    $parser->from_string($source);
  } qr/Illegal number/,
    'missing number is rejected';
};

subtest 'digit instruction rejects values outside 0 to 11' => sub {
  for my $value ( -1, 12 ) {
    my $source = "CF $value\n";
    my $parser = ParserTest->new();

    throws_ok {
      $parser->from_string($source);
    } qr/Expected number from 0 to 11/,
      "CF rejects $value";
  }
};

subtest 'instruction rejects trailing characters' => sub {
  my $source = "RTN extra\n";
  my $parser = ParserTest->new();

  throws_ok {
    $parser->from_string($source);
  } qr/Extra characters/,
    'trailing characters are rejected';

  is( $@->{pos}, index($source, 'extra'), 'failure position' );
};

subtest 'instruction preserves operand diagnostics' => sub {
  for my $case (
    [ 'GTO', qr/Illegal origin address/ ],
    [ 'LBL', qr/Expected variable/ ],
    [ 'FIX', qr/Illegal number/ ],
    [ 'STO', qr/Expected variable/ ],
    [ 'eqn', qr/Expected expression/ ],
  ) {
    my ($source, $message) = @$case;
    my $parser = ParserTest->new();

    throws_ok {
      $parser->from_string("$source\n");
    } $message,
      "$source reports its operand error";
  }
};

done_testing;
