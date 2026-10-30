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

    return $self->any_of(
      sub {
        $self->commit;

        return $self->scope_of(
          undef,
          'parse_macro_block',
          qr/ENDM\b/i,
        );
      },
    );
  }

  $INC{'ParserTest.pm'} = 1;
}

use_ok 'ParserTest';

subtest 'empty macro block' => sub {
  my $parser = ParserTest->new();

  is_deeply(
    $parser->from_string(<<'ASM'),
ENDM
ASM
    {
      lines => [],
    },
    'empty block',
  );
};

subtest 'macro block preserves source lines' => sub {
  my $parser = ParserTest->new();

  is_deeply(
    $parser->from_string(<<'ASM'),
  RTN
  GTO target
  STO target
ENDM
ASM
    {
      lines => [
        'RTN',
        'GTO target',
        'STO target',
      ],
    },
    'macro body remains unparsed source',
  );
};

subtest 'labels remain part of macro source' => sub {
  my $parser = ParserTest->new();

  is_deeply(
    $parser->from_string(<<'ASM'),
again:
  GTO again
ENDM
ASM
    {
      lines => [
        'again:',
        'GTO again',
      ],
    },
    'label and instruction remain source lines',
  );
};

subtest 'label and source may share a line' => sub {
  my $parser = ParserTest->new();

  is_deeply(
    $parser->from_string(<<'ASM'),
again: GTO again
ENDM
ASM
    {
      lines => [
        'again: GTO again',
      ],
    },
    'complete physical macro line is preserved',
  );
};

subtest 'macro body is not validated as HPC syntax' => sub {
  my $parser = ParserTest->new();

  is_deeply(
    $parser->from_string(<<'ASM'),
name "message"
  STO target
  MOV AX,jmp
ENDM
ASM
    {
      lines => [
        'name "message"',
        'STO target',
        'MOV AX,jmp',
      ],
    },
    'macro syntax is validated only after substitution',
  );
};

subtest 'LOCAL declarations are collected and flattened' => sub {
  my $parser = ParserTest->new();

  is_deeply(
    $parser->from_string(<<'ASM'),
  LOCAL again
  LOCAL retry, fallback
again:
  GTO retry
ENDM
ASM
    {
      locals => [
        'AGAIN',
        'RETRY',
        'FALLBACK',
      ],
      lines => [
        'again:',
        'GTO retry',
      ],
    },
    'LOCAL declarations are separated from macro source',
  );
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
    index($parser->{str}, 'LOCAL retry,') + length('LOCAL retry,'),
    'failure position points after comma',
  );
};

subtest 'LOCAL declarations must precede macro source' => sub {
  my $parser = ParserTest->new();

  throws_ok {
    $parser->from_string(<<'ASM');
  RTN
  LOCAL again
ENDM
ASM
  } qr/Unexpected LOCAL in macro line/,
    'LOCAL after first macro line is rejected';

  is(
    $@->{pos},
    index($parser->{str}, 'LOCAL again'),
    'failure position points to LOCAL',
  );
};

done_testing;