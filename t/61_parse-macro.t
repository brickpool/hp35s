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

subtest 'macro call expands into code statements' => sub {
  my $parser = ParserTest->new();

  $parser->{_macro}{definitions}{SAVE} = {
    arguments => ['TARGET'],
    lines     => [
      'STO target',
      'RTN',
    ],
  };
  $parser->{symbols}{SAVE} = 'macro';

  is_deeply(
    $parser->from_string(<<'ASM'),
  1
  SAVE A
  2
END
ASM
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
          literal => {
            value => 1,
            kind  => 'decimal',
          },
        },
        {
          instruction => {
            value   => 'STO',
            operand => {
              type  => 'variable',
              value => 'A',
            },
          },
        },
        {
          instruction => {
            value => 'RTN',
          },
        },
        {
          literal => {
            value => 2,
            kind  => 'decimal',
          },
        },
      ],
    },
    'expanded statements are flattened into surrounding code',
  );
};

subtest 'macro LOCAL labels are unique for each expansion' => sub {
  my $parser = ParserTest->new();

  $parser->{_macro}{definitions}{LOOP} = {
    arguments => [],
    locals    => ['AGAIN'],
    lines     => [
      'again:',
      'GTO again',
    ],
  };
  $parser->{symbols}{LOOP} = 'macro';

  my $code = $parser->from_string(<<'ASM');
  LOOP
  LOOP
END
ASM

  is_deeply(
    $code->{statements},
    [
      {
        directive => {
          type  => 'locals',
          value => 1,
        },
      },
      {
        label => {
          type => 'label',
          name => '??0000',
        },
      },
      {
        instruction => {
          value   => 'GTO',
          operand => {
            type  => 'label',
            value => '??0000',
          },
        },
      },
      {
        label => {
          type => 'label',
          name => '??0001',
        },
      },
      {
        instruction => {
          value   => 'GTO',
          operand => {
            type  => 'label',
            value => '??0001',
          },
        },
      },
    ],
    'each macro expansion gets its own internal label',
  );
};

subtest 'nested macro calls are expanded' => sub {
  my $parser = ParserTest->new();

  $parser->{_macro}{definitions}{INNER} = {
    arguments => ['TARGET'],
    lines     => [
      'STO target',
    ],
  };
  $parser->{_macro}{definitions}{OUTER} = {
    arguments => ['TARGET'],
    lines     => [
      'INNER target',
      'RTN',
    ],
  };
  $parser->{symbols}{INNER} = 'macro';
  $parser->{symbols}{OUTER} = 'macro';

  is_deeply(
    $parser->from_string(<<'ASM'),
  OUTER A
END
ASM
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
            value   => 'STO',
            operand => {
              type  => 'variable',
              value => 'A',
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
    'nested expansion is flattened into code',
  );
};

subtest 'macro recursion is limited' => sub {
  my $parser = ParserTest->new();

  $parser->{_macro}{definitions}{RECUR} = {
    arguments => [],
    lines     => [
      'RECUR',
    ],
  };
  $parser->{symbols}{RECUR} = 'macro';

  throws_ok {
    $parser->from_string(<<'ASM');
  RECUR
END
ASM
  } qr/Maximum macro .*depth|macro .*depth.*exceeded/i,
    'recursive expansion stops at the configured depth limit';
};

subtest 'invalid expanded macro source is rejected' => sub {
  my $parser = ParserTest->new();

  $parser->{_macro}{definitions}{STORE} = {
    arguments => ['TARGET'],
    lines     => [
      'STO target',
    ],
  };
  $parser->{symbols}{STORE} = 'macro';

  throws_ok {
    $parser->from_string(<<'ASM');
  STORE INVALID
END
ASM
  } qr/Expected variable/,
    'expanded source is validated as code';
};

subtest 'multiple macro LOCAL labels get distinct identities' => sub {
  my $parser = ParserTest->new();

  $parser->{_macro}{definitions}{LOOP} = {
    arguments => [],
    locals    => ['FIRST', 'SECOND'],
    lines     => [
      'GTO first',
      'first:',
      'GTO second',
      'second:',
      'RTN',
    ],
  };
  $parser->{symbols}{LOOP} = 'macro';

  my $code = $parser->from_string(<<'ASM');
  LOOP
END
ASM

  is_deeply(
    $code->{statements},
    [
      {
        directive => {
          type  => 'locals',
          value => 1,
        },
      },
      {
        instruction => {
          value   => 'GTO',
          operand => {
            type  => 'label',
            value => '??0000',
          },
        },
      },
      {
        label => {
          type => 'label',
          name => '??0000',
        },
      },
      {
        instruction => {
          value   => 'GTO',
          operand => {
            type  => 'label',
            value => '??0001',
          },
        },
      },
      {
        label => {
          type => 'label',
          name => '??0001',
        },
      },
      {
        instruction => {
          value => 'RTN',
        },
      },
    ],
    'each LOCAL name gets its own internal label',
  );
};

subtest 'dummy label target remains separate from macro LOCAL' => sub {
  my $parser = ParserTest->new();

  $parser->{_macro}{definitions}{BRANCH} = {
    arguments => ['TARGET'],
    locals    => ['AGAIN'],
    lines     => [
      'GTO target',
      'again:',
      'GTO again',
    ],
  };
  $parser->{symbols}{BRANCH} = 'macro';

  my $code = $parser->from_string(<<'ASM');
  BRANCH done
END
ASM

  is_deeply(
    $code->{statements},
    [
      {
        directive => {
          type  => 'locals',
          value => 1,
        },
      },
      {
        instruction => {
          value   => 'GTO',
          operand => {
            type  => 'label',
            value => 'DONE',
          },
        },
      },
      {
        label => {
          type => 'label',
          name => '??0000',
        },
      },
      {
        instruction => {
          value   => 'GTO',
          operand => {
            type  => 'label',
            value => '??0000',
          },
        },
      },
    ],
    'dummy target and macro LOCAL keep separate identities',
  );
};

done_testing;
