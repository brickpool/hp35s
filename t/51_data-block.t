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

    my $data = $self->scope_of(
      undef,
      sub { $self->parse_data_block },
      qr/(?=END\b)/i,
    );

    $self->expect(qr/END\b/i);
    return $data;
  }

  $INC{'ParserTest.pm'} = 1;
}

use_ok 'ParserTest';

subtest 'DATA collects definitions in source order' => sub {
  my $parser = ParserTest->new();

  is_deeply(
    $parser->from_string(<<'ASM'),
FIRST EQU 1
SECOND EQU 2
THIRD EQU 'A+B'
END
ASM
    {
      name        => '_DATA',
      type        => 'data',
      definitions => [
        { name => 'FIRST',  type => 'equation', value => 1 },
        { name => 'SECOND', type => 'equation', value => 2 },
        { name => 'THIRD',  type => 'equation', value => 'A+B' },
      ],
    },
    'definitions are collected in source order',
  );
};

subtest 'DATA applies state directives without retaining nodes' => sub {
  my $parser = ParserTest->new();

  is_deeply(
    $parser->from_string(<<'ASM'),
RADIX 16
FIRST EQU 100
NOLOCALS
SECOND EQU 2
END
ASM
    {
      name        => '_DATA',
      type        => 'data',
      definitions => [
        { name => 'FIRST',  type => 'equation', value => 256 },
        { name => 'SECOND', type => 'equation', value => 2 },
      ],
    },
    'directives affect parsing but are omitted from definitions',
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
DISPLAY "Defining data"
VALUE EQU 1
END
ASM
      {
        name        => '_DATA',
        type        => 'data',
        definitions => [
          { name => 'VALUE', type => 'equation', value => 1 },
        ],
      },
      'DISPLAY is omitted from definitions',
    );
  }

  is( scalar @warnings, 1, 'DISPLAY emits one warning' );
  like( $warnings[0], qr/Defining data/, 'DISPLAY emits its message' );
};

subtest 'DATA adds its section name to the symbol table' => sub {
  my $parser = ParserTest->new();

  $parser->from_string("VALUE EQU 1\nEND\n");

  is( $parser->{symbols}->{_DATA}, 'data', '_DATA is registered as data' );
};

subtest 'empty DATA produces an empty definition list' => sub {
  my $parser = ParserTest->new();

  is_deeply(
    $parser->from_string("END\n"),
    {
      name        => '_DATA',
      type        => 'data',
      definitions => [],
    },
    'empty DATA is accepted',
  );
};

subtest 'DATA rejects statements outside its grammar' => sub {
  my $source = "RTN\nEND\n";
  my $parser = ParserTest->new();

  throws_ok {
    $parser->from_string($source);
  } qr/Illegal instruction/,
    'code instruction is rejected in DATA';

  is( $@->{pos}, 0, 'failure position' );
};

done_testing;
