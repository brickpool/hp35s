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

    my $stack = $self->scope_of(
      undef,
      sub { $self->parse_stack_block },
      qr/(?=END\b)/i,
    );

    $self->expect(qr/END\b/i);
    return $stack;
  }

  $INC{'ParserTest.pm'} = 1;
}

use_ok 'ParserTest';

subtest 'STACK collects register assignments' => sub {
  my $parser = ParserTest->new();

  is_deeply(
    $parser->from_string(<<'ASM'),
REGX SET 1
REGY SET 2
REGZ SET 3
REGT SET 4
END
ASM
    {
      name        => 'STACK',
      type        => 'stack',
      assignments => {
        REGX => { type => 'register', value => 1 },
        REGY => { type => 'register', value => 2 },
        REGZ => { type => 'register', value => 3 },
        REGT => { type => 'register', value => 4 },
      },
    },
    'register assignments are collected',
  );
};

subtest 'later assignments replace earlier values' => sub {
  my $parser = ParserTest->new();

  is_deeply(
    $parser->from_string(<<'ASM'),
REGX SET 1
REGX SET 2
REGX SET 3
END
ASM
    {
      name        => 'STACK',
      type        => 'stack',
      assignments => {
        REGX => { type => 'register', value => 3 },
      },
    },
    'last assignment wins',
  );
};

subtest 'STACK applies state directives without retaining nodes' => sub {
  my $parser = ParserTest->new();

  is_deeply(
    $parser->from_string(<<'ASM'),
RADIX 16
REGX SET 100
NOLOCALS
REGY SET 2
END
ASM
    {
      name        => 'STACK',
      type        => 'stack',
      assignments => {
        REGX => { type => 'register', value => 256 },
        REGY => { type => 'register', value => 2 },
      },
    },
    'directives affect parsing but are omitted from assignments',
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
DISPLAY "Initializing stack"
REGX SET 1
END
ASM
      {
        name        => 'STACK',
        type        => 'stack',
        assignments => {
          REGX => { type => 'register', value => 1 },
        },
      },
      'DISPLAY is omitted from assignments',
    );
  }

  is( scalar @warnings, 1, 'DISPLAY emits one warning' );
  like( $warnings[0], qr/Initializing stack/, 'DISPLAY emits its message' );
};

subtest 'empty STACK produces an empty assignment map' => sub {
  my $parser = ParserTest->new();

  is_deeply(
    $parser->from_string("END\n"),
    {
      name        => 'STACK',
      type        => 'stack',
      assignments => {},
    },
    'empty STACK is accepted',
  );
};

subtest 'STACK rejects statements outside its grammar' => sub {
  my $source = "RTN\nEND\n";
  my $parser = ParserTest->new();

  throws_ok {
    $parser->from_string($source);
  } qr/Illegal instruction/,
    'code instruction is rejected in STACK';

  is( $@->{pos}, 0, 'failure position' );
};

done_testing;
