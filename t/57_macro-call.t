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

        # Establish a known macro definition before parsing its use.
        $self->parse_macro_section;

        return $self->parse_macro_call;
      },
    );
  }

  $INC{'ParserTest.pm'} = 1;
}

use_ok 'ParserTest';

subtest 'macro call is parsed' => sub {
  my $parser = ParserTest->new();

  is_deeply(
    $parser->from_string(<<'ASM'),
MACRO test target
  RTN
ENDM
test MixedCase
ASM
    {
      macro => {
        name      => 'TEST',
        arguments => ['MixedCase'],
      },
    },
    'macro invocation becomes a macro call',
  );
};

subtest 'macro name is case-insensitive' => sub {
  my $parser = ParserTest->new();

  is_deeply(
    $parser->from_string(<<'ASM'),
MACRO Test target
  RTN
ENDM
tEsT Argument
ASM
    {
      macro => {
        name      => 'TEST',
        arguments => ['Argument'],
      },
    },
    'macro name is canonicalized and actual argument keeps its case',
  );
};

subtest 'macro argument count is checked' => sub {
  my $parser = ParserTest->new();

  throws_ok {
    $parser->from_string(<<'ASM');
MACRO test first, second
  RTN
ENDM
test only_one
ASM
  } qr/Wrong number of macro arguments/,
    'too few macro arguments are rejected';
};

subtest 'malformed macro arguments are rejected' => sub {
  my $parser = ParserTest->new();

  throws_ok {
    $parser->from_string(<<'ASM');
MACRO test first, second
  RTN
ENDM
test one,
ASM
  } qr/Illegal macro argument/,
    'missing argument after comma is rejected';

  is(
    $@->{pos},
    index($parser->{str}, 'test one,') + length('test one,'),
    'failure position points after comma',
  );
};

subtest 'macro arguments may contain source text' => sub {
  my $parser = ParserTest->new();

  is_deeply(
    $parser->from_string(<<'ASM'),
MACRO test first,second,third,fourth
ENDM
test 9.1,x<>?,"1, 2",[1,2]
ASM
    {
      macro => {
        name      => 'TEST',
        arguments => [
          '9.1',
          'x<>?',
          '"1, 2"',
          '[1,2]',
        ],
      },
    },
    'source expressions remain complete macro arguments',
  );
};

done_testing;
