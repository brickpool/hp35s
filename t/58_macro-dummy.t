use strict;
use warnings;

use Test::More;
use Parser::HPC;

use_ok 'Parser::HPC';

subtest 'dummy arguments are substituted' => sub {
  my $parser = Parser::HPC->new();

  $parser->{_macro}{definitions}{TEST} = {
    arguments => ['TARGET'],
    lines     => [
      'STO target',
      'GTO target',
      'RTN',
    ],
  };

  is(
    $parser->_substitute_macro_dummies({
      name      => 'TEST',
      arguments => ['A'],
    }),
    "STO A\nGTO A\nRTN",
    'dummy is substituted at every occurrence',
  );
};

subtest 'replacement text is not substituted again' => sub {
  my $parser = Parser::HPC->new();

  $parser->{_macro}{definitions}{TEST} = {
    arguments => ['FIRST', 'SECOND'],
    lines     => [
      'INSTR first,first,second',
    ],
  };

  is(
    $parser->_substitute_macro_dummies({
      name      => 'TEST',
      arguments => ['second', 'X'],
    }),
    'INSTR second,second,X',
    'replacement does not trigger another dummy substitution',
  );
};

subtest 'dummy names inside strings are preserved' => sub {
  my $parser = Parser::HPC->new();

  $parser->{_macro}{definitions}{TEST} = {
    arguments => ['TARGET'],
    lines     => [
      q{eqn "target" target},
      q{eqn 'target' target},
    ],
  };

  is(
    $parser->_substitute_macro_dummies({
      name      => 'TEST',
      arguments => ['A'],
    }),
    qq{eqn "target" A\neqn 'target' A},
    'quoted dummy names remain literal',
  );
};

subtest 'identifiers containing a dummy name are preserved' => sub {
  my $parser = Parser::HPC->new();

  $parser->{_macro}{definitions}{TEST} = {
    arguments => ['TARGET'],
    lines     => [
      'target target1 mytarget',
    ],
  };

  is(
    $parser->_substitute_macro_dummies({
      name      => 'TEST',
      arguments => ['A'],
    }),
    'A target1 mytarget',
    'only complete identifiers are substituted',
  );
};

subtest 'macro without dummy arguments keeps source unchanged' => sub {
  my $parser = Parser::HPC->new();

  $parser->{_macro}{definitions}{TEST} = {
    arguments => [],
    lines     => [
      'RTN',
    ],
  };

  is(
    $parser->_substitute_macro_dummies({
      name      => 'TEST',
      arguments => [],
    }),
    'RTN',
    'source without dummy arguments is unchanged',
  );
};

subtest 'macro definition remains unchanged' => sub {
  my $parser = Parser::HPC->new();

  $parser->{_macro}{definitions}{TEST} = {
    arguments => ['TARGET'],
    lines     => [
      'STO target',
      'GTO target',
    ],
  };

  is(
    $parser->_substitute_macro_dummies({
      name      => 'TEST',
      arguments => ['A'],
    }),
    "STO A\nGTO A",
    'first expansion',
  );

  is(
    $parser->_substitute_macro_dummies({
      name      => 'TEST',
      arguments => ['B'],
    }),
    "STO B\nGTO B",
    'second expansion uses original macro source',
  );

  is_deeply(
    $parser->{_macro}{definitions}{TEST}{lines},
    [
      'STO target',
      'GTO target',
    ],
    'macro definition is unchanged',
  );
};

subtest 'dummy may look like HP35s syntax' => sub {
  my $parser = Parser::HPC->new();

  $parser->{_macro}{definitions}{TEST} = {
    arguments => ['I'],
    lines     => [
      'STO+ I',
    ],
  };

  is(
    $parser->_substitute_macro_dummies({
      name      => 'TEST',
      arguments => ['(I)'],
    }),
    'STO+ (I)',
    'dummy substitution happens before HP35s syntax validation',
  );
};

done_testing;
