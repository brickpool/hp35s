use strict;
use warnings;

use Test::More;

{
  package ParserTest;
  use parent 'Parser::HPC';

  sub from_string {
    goto &Parser::MGC::from_string;
  }

  sub parse {
    return shift->any_of('parse_code_block');
  }

  $INC{'ParserTest.pm'} = 1;
}

use_ok 'ParserTest';

subtest 'label scope is preserved for later fix-up' => sub {
  my $parser = ParserTest->new();

  is_deeply(
    $parser->from_string(<<'ASM'),
start:
@@loop:
  GTO @@loop
next:
@@loop:
  XEQ @@loop
ASM
    {
      name       => '_TEXT',
      type       => 'code',
      statements => [
        { directive => { type => 'locals', value => 1 } },
        { label => { type => 'label', name => 'START' } },
        { label => { type => 'label', name => '@@LOOP' } },
        {
          instruction => {
            value   => 'GTO',
            operand => { type => 'label', value => '@@LOOP' },
          },
        },
        { label => { type => 'label', name => 'NEXT' } },
        { label => { type => 'label', name => '@@LOOP' } },
        {
          instruction => {
            value   => 'XEQ',
            operand => { type => 'label', value => '@@LOOP' },
          },
        },
      ],
    },
    'local labels and references remain unresolved',
  );
};

subtest 'LOCALS state is preserved in statement order' => sub {
  my $parser = ParserTest->new();

  is_deeply(
    $parser->from_string(<<'ASM'),
start:
  @@local:
  GTO @@local
NOLOCALS
  @@shared:
  GTO @@shared
LOCALS
  next:
  @@local:
  XEQ @@local
ASM
    {
      name       => '_TEXT',
      type       => 'code',
      statements => [
        { directive => { type => 'locals', value => 1 } },
        { label => { type => 'label', name => 'START' } },
        { label => { type => 'label', name => '@@LOCAL' } },
        {
          instruction => {
            value   => 'GTO',
            operand => { type => 'label', value => '@@LOCAL' },
          },
        },
        { directive => { type => 'locals', value => 0 } },
        { label => { type => 'label', name => '@@SHARED' } },
        {
          instruction => {
            value   => 'GTO',
            operand => { type => 'label', value => '@@SHARED' },
          },
        },
        { directive => { type => 'locals', value => 1 } },
        { label => { type => 'label', name => 'NEXT' } },
        { label => { type => 'label', name => '@@LOCAL' } },
        {
          instruction => {
            value   => 'XEQ',
            operand => { type => 'label', value => '@@LOCAL' },
          },
        },
      ],
    },
    'LOCALS and NOLOCALS remain ordered with labels and references',
  );
};

subtest 'fix-up resolves scoped local labels and references' => sub {
  my $parser = ParserTest->new();

  my $code = $parser->from_string(<<'ASM');
start:
@@loop:
  GTO @@loop
next:
  XEQ @@loop
@@loop:
ASM

  my $ast = { segments => [ $code ] };
  $parser->_fixup_labels($ast);

  is_deeply(
    $ast->{segments}[0],
    {
      name       => '_TEXT',
      type       => 'code',
      statements => [
        { label => { name => 'START' } },
        { label => { name => '@@0001' } },
        {
          instruction => {
            value   => 'GTO',
            operand => { type => 'label', value => '@@0001' },
          },
        },
        { label => { name => 'NEXT' } },
        {
          instruction => {
            value   => 'XEQ',
            operand => { type => 'label', value => '@@0002' },
          },
        },
        { label => { name => '@@0002' } },
      ],
    },
    'scoped labels and forward references use generated identities',
  );
};

subtest 'fix-up honors NOLOCALS and removes directives' => sub {
  my $parser = ParserTest->new();

  my $code = $parser->from_string(<<'ASM');
NOLOCALS
@@shared:
  GTO @@shared
next:
  XEQ @@shared
ASM

  my $ast = { segments => [ $code ] };
  $parser->_fixup_labels($ast);

  is_deeply(
    $ast->{segments}[0],
    {
      name       => '_TEXT',
      type       => 'code',
      statements => [
        { label => { name => '@@SHARED' } },
        {
          instruction => {
            value   => 'GTO',
            operand => { type => 'label', value => '@@SHARED' },
          },
        },
        { label => { name => 'NEXT' } },
        {
          instruction => {
            value   => 'XEQ',
            operand => { type => 'label', value => '@@SHARED' },
          },
        },
      ],
    },
    'NOLOCALS keeps double-at labels global',
  );
};

done_testing;
