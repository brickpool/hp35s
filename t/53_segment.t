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

    my $segment = $self->any_of('parse_segment');
    $self->expect(qr/END\b/i);

    return $segment;
  }

  $INC{'ParserTest.pm'} = 1;
}

use_ok 'ParserTest';

subtest 'STACK dispatches to the stack block parser' => sub {
  my $parser = ParserTest->new();

  is_deeply(
    $parser->from_string(<<'ASM'),
STACK
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
    'STACK returns a stack section',
  );
};

subtest 'DATASEG dispatches to the data block parser' => sub {
  my $parser = ParserTest->new();

  is_deeply(
    $parser->from_string(<<'ASM'),
DATASEG
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
    'DATASEG returns a data section',
  );
};

subtest 'CODESEG dispatches to the code block parser' => sub {
  my $parser = ParserTest->new();

  is_deeply(
    $parser->from_string(<<'ASM'),
CODESEG
RTN
END
ASM
    {
      name       => '_TEXT',
      type       => 'code',
      statements => [
        { directive => { type => 'locals', value => 1 } },
        { instruction => { value => 'RTN' } },
      ],
    },
    'CODESEG returns a code section',
  );
};

subtest 'segment keywords are case-insensitive' => sub {
  for my $case (
    [ 'stack',   'stack', 'STACK' ],
    [ 'dataseg', 'data',  '_DATA' ],
    [ 'codeseg', 'code',  '_TEXT' ],
  ) {
    my ($keyword, $type, $name) = @$case;
    my $parser = ParserTest->new();

    is_deeply(
      $parser->from_string("$keyword\nEND\n"),
      {
        name => $name,
        type => $type,
        $type eq 'stack' ? ( assignments => {} ) :
        $type eq 'data'  ? ( definitions => [] ) :
                           ( statements  => [
                              { 
                                directive => { 
                                  type => 'locals', 
                                  value => 1
                                },
                              },
                            ],
                          ),
      },
      "$keyword is accepted",
    );
  }
};

subtest 'segment stops before END' => sub {
  for my $keyword ( qw(STACK DATASEG CODESEG) ) {
    my $source = "$keyword\nEND\n";
    my $parser = ParserTest->new();

    lives_ok {
      $parser->from_string($source);
    } "$keyword terminates at END";
  }
};

subtest 'unknown segment keyword is rejected' => sub {
  my $source = "UNKNOWN\nEND\n";
  my $parser = ParserTest->new();

  throws_ok {
    $parser->from_string($source);
  } qr/./,
    'unknown segment is rejected';

  is( $@->{pos}, 0, 'failure position' );
};

done_testing;
