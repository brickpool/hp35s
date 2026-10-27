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

    my $name = 'TEST';
    $self->{_macro}{$name}{arguments} = ['TARGET'];

    local $self->{_macro_name} = $name;

    my $result = $self->scope_of(
      undef,
      sub { $self->parse_macro_block($name) },
      qr/(?=ENDM\b)/i,
    );

    $self->expect(qr/ENDM\b/i);
    return $result;
  }

  $INC{'ParserTest.pm'} = 1;
}

use_ok 'ParserTest';

subtest 'empty macro block' => sub {
  my $parser = ParserTest->new();

  is_deeply(
    $parser->from_string("ENDM\n"),
    {
      statements => [],
    },
    'empty block',
  );
};

subtest 'macro block parses instructions' => sub {
  my $parser = ParserTest->new();

  is_deeply(
    $parser->from_string("RTN\nENDM\n"),
    {
      statements => [
        {
          instruction => {
            value => 'RTN',
          },
        },
      ],
    },
    'instruction',
  );
};

subtest 'macro block parses labels and instructions' => sub {
  my $parser = ParserTest->new();

  is_deeply(
    $parser->from_string(<<'ASM'),
again:
RTN
ENDM
ASM
    {
      statements => [
        {
          label => {
            type => 'label',
            name => 'AGAIN',
          },
        },
        {
          instruction => {
            value => 'RTN',
          },
        },
      ],
    },
    'label and instruction',
  );
};

subtest 'macro block parses ordinary code constructs' => sub {
  my $parser = ParserTest->new();

  is_deeply(
    $parser->from_string(<<'ASM'),
again: RTN
ENDM
ASM
    {
      statements => [
        {
          label => {
            type => 'label',
            name => 'AGAIN',
          },
        },
        {
          instruction => {
            value => 'RTN',
          },
        },
      ],
    },
    'label and instruction may share a line',
  );
};

subtest 'illegal macro block instruction is rejected' => sub {
  my $parser = ParserTest->new();

  throws_ok {
    $parser->from_string(<<'ASM');
UNKNOWN statement
ENDM
ASM
  } qr/Illegal instruction/,
    'illegal instruction';
};

subtest 'invalid LOCAL declarations fail inside macro block' => sub {
  my $parser = ParserTest->new();

  throws_ok {
    $parser->from_string(<<'ASM');
LOCAL again,
ENDM
ASM
  } qr/Illegal local argument/,
    'invalid LOCAL argument is not swallowed by sequence_of';

  $parser = ParserTest->new();

  throws_ok {
    $parser->from_string(<<'ASM');
LOCAL again
LOCAL retry,
ENDM
ASM
  } qr/Illegal local argument/,
    'error in later LOCAL declaration is preserved';
  is(
    $@->{pos},
    index($parser->{str}, ',') + 1,
    'failure position points after comma',
  );
};

subtest 'LOCAL declarations must precede macro statements' => sub {
  my $parser = ParserTest->new();

  throws_ok {
    $parser->from_string(<<'ASM');
RTN
LOCAL again
ENDM
ASM
  } qr/Illegal instruction/,
    'LOCAL after first macro statement is rejected';

  is(
    $@->{pos},
    index($parser->{str}, 'LOCAL'),
    'failure position points to LOCAL',
  );
};

subtest 'macro dummy is classified in address operand' => sub {
  my $parser = ParserTest->new();

  $parser->{_macro}{TEST}{arguments} = ['TARGET'];

  is_deeply(
    $parser->from_string(<<'ASM'),
GTO target
ENDM
ASM
    {
      statements => [
        {
          instruction => {
            value   => 'GTO',
            operand => {
              type  => 'dummy',
              value => 'TARGET',
            },
          },
        },
      ],
    },
    'GTO operand is classified as a macro dummy',
  );
};

subtest 'macro LOCAL wins over dummy in address context' => sub {
  my $parser = ParserTest->new();

  $parser->{_macro}{TEST}{arguments} = ['TARGET'];

  is_deeply(
    $parser->from_string(<<'ASM'),
LOCAL target
GTO target
ENDM
ASM
    {
      locals => ['TARGET'],
      statements => [
        {
          instruction => {
            value   => 'GTO',
            operand => {
              type  => 'local',
              value => 'TARGET',
            },
          },
        },
      ],
    },
    'LOCAL wins over dummy for an address operand',
  );
};

subtest 'macro dummy wins over LOCAL in non-address operand' => sub {
  my $parser = ParserTest->new();

  $parser->{_macro}{TEST} = {
    arguments => ['TARGET'],
  };

  is_deeply(
    $parser->from_string(<<'ASM'),
  LOCAL target
  STO target
  VIEW target
ENDM
ASM
    {
      locals => ['TARGET'],
      statements => [
        {
          instruction => {
            value   => 'STO',
            operand => {
              type  => 'dummy',
              value => 'TARGET',
            },
          },
        },
        {
          instruction => {
            value   => 'VIEW',
            operand => {
              type  => 'dummy',
              value => 'TARGET',
            },
          },
        },
      ],
    },
    'STO and VIEW operands use dummy instead of macro LOCAL',
  );
};

done_testing;
