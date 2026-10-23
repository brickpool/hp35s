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

    my $code = $self->scope_of(
      undef,
      sub { $self->parse_code_block },
      qr/(?=END\b)/i,
    );

    $self->expect(qr/END\b/i);
    return $code;
  }

  $INC{'ParserTest.pm'} = 1;
}

use_ok 'ParserTest';

subtest 'CODE collects labels, instructions and literals in order' => sub {
  my $parser = ParserTest->new();

  is_deeply(
    $parser->from_string(<<'ASM'),
start:
  RTN
value:
  12d
  GTO start
END
ASM
    {
      name       => '_TEXT',
      type       => 'code',
      statements => [
        { label => { name => 'START' } },
        { instruction => { value => 'RTN' } },
        { label => { name => 'VALUE' } },
        { literal => { kind => 'decimal', value => '12d' } },
        {
          instruction => {
            value   => 'GTO',
            operand => { type => 'label', value => 'START' },
          },
        },
      ],
    },
    'statements are collected in source order',
  );
};

subtest 'CODE applies state directives without retaining nodes' => sub {
  my $parser = ParserTest->new();

  is_deeply(
    $parser->from_string(<<'ASM'),
RADIX 16
LOCALS
start:
  100
NOLOCALS
  RTN
END
ASM
    {
      name       => '_TEXT',
      type       => 'code',
      statements => [
        { label => { name => 'START' } },
        { literal => { kind => 'hex', value => '100h' } },
        { instruction => { value => 'RTN' } },
      ],
    },
    'directives affect parsing but are omitted from statements',
  );

  is( $parser->{radix}, 16, 'RADIX changes parser state' );
  is( $parser->{locals}, 0, 'NOLOCALS changes parser state' );
};

subtest 'DISPLAY is applied without retaining a node' => sub {
  my $parser = ParserTest->new();
  my @warnings;

  {
    local $SIG{__WARN__} = sub { push @warnings, @_ };

    is_deeply(
      $parser->from_string(<<'ASM'),
DISPLAY "Entering code"
  RTN
END
ASM
      {
        name       => '_TEXT',
        type       => 'code',
        statements => [
          { instruction => { value => 'RTN' } },
        ],
      },
      'DISPLAY is omitted from statements',
    );
  }

  is( scalar @warnings, 1, 'DISPLAY emits one warning' );
  like( $warnings[0], qr/Entering code/, 'DISPLAY emits its message' );
};

subtest 'CODE accepts trailing whitespace and comments' => sub {
  my $parser = ParserTest->new();

  is_deeply(
    $parser->from_string(<<'ASM'),
start:
  RTN         ; return
  0           ; zero
  pi          ; constant
  GTO start   ; jump
  STOP
END
ASM
    {
      name       => '_TEXT',
      type       => 'code',
      statements => [
        { label => { name => 'START' } },
        { instruction => { value => 'RTN' } },
        { literal => { kind => 'decimal', value => '0' } },
        { literal => { kind => 'constant', value => 'pi' } },
        {
          instruction => {
            value   => 'GTO',
            operand => { type => 'label', value => 'START' },
          },
        },
        { instruction => { value => 'STOP' } },
      ],
    },
    'comments and whitespace preserve statement boundaries',
  );
};

subtest 'CODE adds its section name to the symbol table' => sub {
  my $parser = ParserTest->new();

  $parser->from_string("RTN\nEND\n");

  is( $parser->{symbols}->{_TEXT}, 'code', '_TEXT is registered as code' );
};

subtest 'empty CODE produces an empty statement list' => sub {
  my $parser = ParserTest->new();

  is_deeply(
    $parser->from_string("END\n"),
    {
      name       => '_TEXT',
      type       => 'code',
      statements => [],
    },
    'empty CODE is accepted',
  );
};

subtest 'CODE rejects statements outside its grammar' => sub {
  my $source = "UNKNOWN\nEND\n";
  my $parser = ParserTest->new();

  throws_ok {
    $parser->from_string($source);
  } qr/Illegal instruction/,
    'unknown statement is rejected in CODE';

  is( $@->{pos}, 0, 'failure position' );
};

subtest 'CODE rejects extra tokens after a statement' => sub {
  for my $code (
    'RTN       extra',
    '0         extra',
    'GTO start extra',
  ) {
    my $parser = ParserTest->new();

    throws_ok {
      $parser->from_string(<<ASM);
start:
  $code
END
ASM
    } qr/Extra characters/,
      "$code rejects extra tokens";
  }
};

done_testing;
