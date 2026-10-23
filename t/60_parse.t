use strict;
use warnings;

use Test::More;
use Test::Exception;
use Parser::HPC;

use_ok 'Parser::HPC';

subtest 'parse combines header, segments and END' => sub {
  my $root = Parser::HPC->new->from_string(<<'ASM');
%TITLE "Integration"
IDEAL
P35S
MODEL TINY
DATASEG
VALUE EQU 1
STACK
REGX SET 2
CODESEG
start:
  RTN
END start
ASM

  is_deeply(
    $root,
    {
      title    => 'Integration',
      mode     => 'IDEAL',
      language => 'P35S',
      model    => 0,
      segments => [
        {
          name        => '_DATA',
          type        => 'data',
          definitions => [
            { name => 'VALUE', type => 'equation', value => 1 },
          ],
        },
        {
          name        => 'STACK',
          type        => 'stack',
          assignments => {
            REGX => { type => 'register', value => 2 },
          },
        },
        {
          name       => '_TEXT',
          type       => 'code',
          statements => [
            { label => { name => 'START' } },
            { instruction => { value => 'RTN' } },
          ],
        },
      ],
      startaddr => { type => 'label', value => 'START' },
    },
    'root AST contains header, sections and start address',
  );
};

subtest 'parse merges repeated sections by type' => sub {
  my $root = Parser::HPC->new->from_string(<<'ASM');
MODEL TINY
CODESEG
first:
  RTN
DATASEG
DATA_ONE EQU 1
STACK
REGX SET 1
CODESEG
second:
  STOP
DATASEG
DATA_TWO EQU 2
STACK
REGY SET 2
END first
ASM

  is_deeply(
    $root->{segments},
    [
      {
        name       => '_TEXT',
        type       => 'code',
        statements => [
          { label => { name => 'FIRST' } },
          { instruction => { value => 'RTN' } },
          { label => { name => 'SECOND' } },
          { instruction => { value => 'STOP' } },
        ],
      },
      {
        name        => '_DATA',
        type        => 'data',
        definitions => [
          { name => 'DATA_ONE', type => 'equation', value => 1 },
          { name => 'DATA_TWO', type => 'equation', value => 2 },
        ],
      },
      {
        name        => 'STACK',
        type        => 'stack',
        assignments => {
          REGX => { type => 'register', value => 1 },
          REGY => { type => 'register', value => 2 },
        },
      },
    ],
    'repeated sections are merged into their first section node',
  );
};

subtest 'END start reference is optional' => sub {
  my $root = Parser::HPC->new->from_string(<<'ASM');
MODEL TINY
CODESEG
  RTN
END
ASM

  ok(
    !exists $root->{startaddr}, 
    'root has no start address without END operand'
  );
};

TODO: {
  local $TODO = "parse_header currently reports 'Illegal instruction'";
    # ... before parse can report undeclared segment

  subtest 'parse rejects emission before a segment' => sub {
    my $source = <<'ASM';
MODEL TINY
RTN
END
ASM

    throws_ok {
      Parser::HPC->new->from_string($source);
    } qr/Code or data emission to undeclared segment/,
      'statement before a segment is rejected';
  };
}

subtest 'parse requires END' => sub {
  my $source = <<'ASM';
MODEL TINY
CODESEG
  RTN
ASM

  throws_ok {
    Parser::HPC->new->from_string($source);
  } qr/Unexpected end of file \(no END directive\)/,
    'missing END is rejected';
};

subtest 'parse rejects unsupported segment spelling' => sub {
  for my $source (
    "MODEL TINY\nSEGMENT CODE\nRTN\nENDS\nEND\n",
    "MODEL TINY\nCODESEG\nRTN\nENDS\nEND\n",
    "MODEL TINY\n.DATA\n.CODE\n.STACK 4\nEND\n",
  ) {
    dies_ok {
      Parser::HPC->new->from_string($source);
    } 'unsupported segment spelling is rejected';
  }
};

done_testing;
