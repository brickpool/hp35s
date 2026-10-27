use strict;
use warnings;

use Test::More;
use Test::Exception;

use Parser::HPC;

my @valid = qw(
  START
  start
  _start
  _123
  123
  12ab
  A1
  A_B
  A$B
  A?B
  @A
  @1
  @@A
  @@012
  ?A
  ?abc
  $A
  $2
  ??012
  ??ABCD
);

my @invalid = qw(
  $
  ?
  @
  @@
  ??0000
  ??0001
  ??9999
  @@0000
  @@0001
  @@9999
);

subtest 'label token' => sub {
  for my $source ( @valid ) {
    my $parser = Parser::HPC->new(toplevel => 'token_label');

    is(
      $parser->from_string("$source\n"),
      $source,
      "$source is accepted",
    );
  }

  for my $source ( @invalid ) {
    my $parser = Parser::HPC->new(toplevel => 'token_label');

    dies_ok {
      $parser->from_string("$source\n");
    } "$source is rejected";
  }
};

done_testing;
