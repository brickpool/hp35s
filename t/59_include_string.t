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

    return $self->include_string(
      $self->{macro_source},
      toplevel => 'parse_code_block',
    );
  }

  $INC{'ParserTest.pm'} = 1;
}

use_ok 'ParserTest';

subtest 'macro source is parsed as code' => sub {
  my $parser = ParserTest->new();
  $parser->{macro_source} = "RTN\n";

  is_deeply(
    $parser->from_string(''),
    {
      name       => '_TEXT',
      type       => 'code',
      statements => [
        {
          directive => {
            type  => 'locals',
            value => 1,
          },
        },
        {
          instruction => {
            value => 'RTN',
          },
        },
      ],
    },
    'macro source is parsed as code',
  );
};

subtest 'macro LOCAL labels are classified' => sub {
  my $parser = ParserTest->new();

  $parser->{_macro}{definitions}{TEST} = {
    arguments => [],
    locals    => ['AGAIN'],
    lines     => [],
  };
  $parser->{_macro}{name} = 'TEST';
  $parser->{macro_source} = <<'ASM';
again:
GTO again
XEQ again
RTN
ASM

  is_deeply(
    $parser->from_string(''),
    {
      name       => '_TEXT',
      type       => 'code',
      statements => [
        {
          directive => {
            type  => 'locals',
            value => 1,
          },
        },
        {
          label => {
            type => 'macro',
            name => 'AGAIN',
          },
        },
        {
          instruction => {
            value   => 'GTO',
            operand => {
              type  => 'macro',
              value => 'AGAIN',
            },
          },
        },
        {
          instruction => {
            value   => 'XEQ',
            operand => {
              type  => 'macro',
              value => 'AGAIN',
            },
          },
        },
        {
          instruction => {
            value => 'RTN',
          },
        },
      ],
    },
    'macro LOCAL label and address references are classified as macro'
  );
};

subtest 'ordinary labels remain ordinary labels' => sub {
  my $parser = ParserTest->new();

  $parser->{_macro}{definitions}{TEST} = {
    arguments => [],
    locals    => ['AGAIN'],
    lines     => [],
  };
  $parser->{_macro_name} = 'TEST';
  $parser->{macro_source} = <<'ASM';
start:
GTO start
ASM

  is_deeply(
    $parser->from_string(''),
    {
      name       => '_TEXT',
      type       => 'code',
      statements => [
        {
          directive => {
            type  => 'locals',
            value => 1,
          },
        },
        {
          label => {
            type => 'label',
            name => 'START',
          },
        },
        {
          instruction => {
            value   => 'GTO',
            operand => {
              type  => 'label',
              value => 'START',
            },
          },
        },
      ],
    },
    'label not declared with LOCAL remains an ordinary label',
  );
};

subtest 'current LOCALS state is preserved' => sub {
  my $parser = ParserTest->new();

  $parser->{locals} = 0;
  $parser->{macro_source} = "RTN\n";

  is_deeply(
    $parser->from_string(''),
    {
      name       => '_TEXT',
      type       => 'code',
      statements => [
        {
          directive => {
            type  => 'locals',
            value => 0,
          },
        },
        {
          instruction => {
            value => 'RTN',
          },
        },
      ],
    },
    'macro source inherits current NOLOCALS state',
  );
};

subtest 'invalid macro source is rejected' => sub {
  my $parser = ParserTest->new();
  $parser->{macro_source} = "STO invalid\n";

  throws_ok {
    $parser->from_string('');
  } qr/Expected variable/,
    'expanded macro source is validated as code';
};

done_testing;
