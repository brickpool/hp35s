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

    my $section = $self->any_of( 'parse_macro_section' );

    return $section;
  }

  $INC{'ParserTest.pm'} = 1;
}

use_ok 'ParserTest';

subtest 'macro section is parsed' => sub {
  my $parser = ParserTest->new();

  is_deeply(
    $parser->from_string(<<'ASM'),
MACRO test
ENDM
ASM
    {
      macro => {
        TEST => {
          arguments => [],
          lines     => [],
        },
      },
    },
    'empty macro',
  );

  is( $parser->{symbols}{TEST}, 'macro', 'macro symbol is registered' );
};

subtest 'macro section combines header and block' => sub {
  my $parser = ParserTest->new();

  is_deeply(
    $parser->from_string(<<'ASM'),
MACRO test target
  LOCAL again
  LOCAL retry
again:
  GTO again
  RTN
ENDM
ASM
    {
      macro => {
        TEST => {
          arguments => ['TARGET'],
          locals    => ['AGAIN', 'RETRY'],
          lines     => [
            'again:',
            'GTO again',
            'RTN',
          ],
        },
      },
    },
    'header and block form one macro section',
  );

  is(
    $parser->{symbols}{TEST},
    'macro',
    'macro symbol is registered after successful section',
  );
};

subtest 'macro symbol is canonicalized' => sub {
  my $parser = ParserTest->new();

  $parser->from_string(<<'ASM');
Macro Test
ENDM
ASM

  is(
    $parser->{symbols}{TEST},
    'macro',
    'canonical macro symbol is registered',
  );
};

subtest 'missing ENDM is rejected' => sub {
  my $parser = ParserTest->new();

  throws_ok {
    $parser->from_string(<<'ASM');
MACRO test
  RTN
ASM
  } qr/Expected .+?ENDM/,
    'ENDM is required';

  ok(
    !exists $parser->{symbols}{TEST},
    'incomplete macro is not registered',
  );
};

subtest 'macro block failure is preserved' => sub {
  my $parser = ParserTest->new();

  throws_ok {
    $parser->from_string(<<'ASM');
MACRO test
LOCAL again
LOCAL retry,
ENDM
ASM
  } qr/Illegal local argument/,
    'LOCAL failure is propagated through macro section';

  is(
    $@->{pos},
    index($parser->{str}, 'LOCAL retry,') + length('LOCAL retry,'),
    'failure position points after comma',
  );

  ok( !exists $parser->{symbols}{TEST}, 'failed macro is not registered' );
};

subtest 'existing symbol prevents macro definition' => sub {
  my $parser = ParserTest->new();

  $parser->{symbols}{TEST} = 'label';

  throws_ok {
    $parser->from_string(<<'ASM');
MACRO test
ENDM
END
ASM
  } qr/Symbol already different kind/,
    'macro cannot redefine an existing different symbol';

  is(
    $parser->{symbols}{TEST},
    'label',
    'existing symbol remains unchanged',
  );
};

subtest 'duplicate macro definition is rejected' => sub {
  my $parser = ParserTest->new();

  $parser->{symbols}{TEST} = 'macro';

  throws_ok {
    $parser->from_string(<<'ASM');
MACRO test
ENDM
END
ASM
  } qr/Symbol already defined/,
    'existing macro cannot be redefined';
};

done_testing;
