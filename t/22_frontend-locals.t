use strict;
use warnings;

use Test::More;
use Parser::HPC;
use lib 't/lib';
use FrontendTest qw( run_frontend );

subtest 'LOCALS scopes forward and backward jumps by nonlocal labels' => sub {
  my $source = <<'ASM';
MODEL P35S
LOCALS ; fixed prefix
SEGMENT CODE
start:
  LBL A
  GTO @@loop
@@loop:
  RPN
  XEQ @@LOOP
next:
  GTO @@loop
@@loop:
  RTN
  GTO @@loop
ENDS
END start
ASM
  my $root = Parser::HPC->new->from_string($source);
  my $statements = $root->{segments}->{_TEXT}->{statements};
  is( scalar @$statements, 7, 'LOCALS emits no instruction' );
  my $first = $statements->[1]->{instruction}->{operand}->{value};
  my $second = $statements->[4]->{instruction}->{operand}->{value};
  isnt( $first, $second, 'same local spelling has distinct scoped identities' );
  is( $statements->[3]->{instruction}->{operand}->{value}, $first,
    'case-insensitive backward reference retains first scope' );
  is( $statements->[6]->{instruction}->{operand}->{value}, $second,
    'backward reference retains second scope' );
  is( $root->{labels}->{$first}->{statement}, 2, 'first local target' );
  is( $root->{labels}->{$second}->{statement}, 5, 'second local target' );
  for my $options ( [], [ '-j' ], [ '-s' ] ) {
    my ($first_scope, $next_scope) = split /(?=^next:)/m, $source;
    $first_scope =~ s/^LOCALS[^\n]*\n//m;
    $first_scope =~ s/\@\@loop/first_loop/ig;
    $next_scope =~ s/\@\@loop/second_loop/ig;
    my $explicit = $first_scope . $next_scope;
    my ($status, $output, $errors) = run_frontend($source, @$options);
    my ($expected_status, $expected, $expected_errors) =
      run_frontend($explicit, @$options);
    is( $status, 0, 'local source assembles' );
    is( $errors, '', 'no missing local targets' );
    is( $expected_status, 0, 'global reference assembles' );
    is( $expected_errors, '', 'global reference has no warnings' );
    is( $output, $expected, 'local and explicit targets produce identical output' );
  }
};

subtest 'NOLOCALS disables special handling without emitting code' => sub {
  my $root = Parser::HPC->new->from_string(<<'ASM');
MODEL P35S
SEGMENT CODE
start:
LOCALS
@@loop:
GTO @@loop
NOLOCALS
@@loop:
GTO @@loop
next:
XEQ @@loop
LOCALS
@@loop:
GTO @@loop
ENDS
END @@loop
ASM
  my $statements = $root->{segments}->{_TEXT}->{statements};
  is( scalar @$statements, 4, 'both directives leave instruction indices unchanged' );
  is( $statements->[1]->{instruction}->{operand}->{value}, '@@LOOP',
    'disabled local name remains global' );
  is( $statements->[2]->{instruction}->{operand}->{value}, '@@LOOP',
    'nonlocal label does not restrict ordinary global reference' );
  is( $root->{labels}->{'@@LOOP'}->{statement}, 1, 'global target is retained' );
  is( $root->{startaddr}, $statements->[3]->{instruction}->{operand}->{value},
    'END resolves a local label in the current scope' );
};

subtest 'local scope follows labels rather than segments or directives' => sub {
  my $root = Parser::HPC->new->from_string(<<'ASM');
MODEL P35S
LOCALS
SEGMENT first CODE
@@initial:
GTO @@initial
start:
GTO @@target
ENDS first
NOLOCALS
LOCALS
SEGMENT second CODE
@@target:
RTN
ENDS second
END
ASM
  my $target = $root->{segments}->{FIRST}->{statements}->[1]
    ->{instruction}->{operand}->{value};
  is( $root->{labels}->{$target}->{segment}, 'SECOND',
    'segment and mode changes do not start a new scope' );
  my $initial = $root->{segments}->{FIRST}->{statements}->[0]
    ->{instruction}->{operand}->{value};
  is( $root->{labels}->{$initial}->{statement}, 0,
    'locals before the first nonlocal label have an initial scope' );
};

subtest 'only double-at prefixes are local and references do not escape scope' => sub {
  my $root = Parser::HPC->new->from_string(<<'ASM');
MODEL P35S
LOCALS
SEGMENT CODE
start:
@@A001:
RTN
GTO @@A001
@shared:
RPN
next:
GTO @@A001
GTO @shared
ENDS
END start
ASM
  my $statements = $root->{segments}->{_TEXT}->{statements};
  my $local = $statements->[1]->{instruction}->{operand};
  is( $local->{type}, 'label', '@@A001 is not a literal calculator address' );
  is( $root->{labels}->{$local->{value}}->{statement}, 0,
    'address-like local name resolves normally' );
  my $other = $statements->[3]->{instruction}->{operand}->{value};
  ok( !exists $root->{labels}->{$other},
    'reference in another scope does not resolve to earlier local definition' );
  is( $statements->[4]->{instruction}->{operand}->{value}, '@SHARED',
    'single-at name remains global under LOCALS' );
};

subtest 'LOCALS and NOLOCALS require uppercase spelling' => sub {
  for my $directive ( 'locals', 'Locals', 'LoCaLs', 'nolocals', 'Nolocals', 'NoLoCaLs' ) {
    for my $source (
      "MODEL P35S\n$directive\nSEGMENT CODE\nRTN\nENDS\nEND\n",
      "MODEL P35S\nSEGMENT CODE\n$directive\nRTN\nENDS\nEND\n",
      "MODEL P35S\nSEGMENT DATA\n$directive\nVALUE EQU 1\nENDS\nEND\n",
      "MODEL P35S\nSEGMENT STACK\n$directive\nREGX SET 1\nENDS\nEND\n",
    ) {
      my $success = eval { Parser::HPC->new->from_string($source); 1 };
      ok( !$success, "$directive is rejected" );
    }
  }
};

subtest 'duplicate locals and unsupported directive parameters are rejected' => sub {
  for my $code (
    "LOCALS\nstart:\n\@\@loop:\nRTN\n\@\@loop:\nRTN",
    "NOLOCALS\nstart:\n\@\@loop:\nRTN\nnext:\n\@\@loop:\nRTN",
    "start:\n\@\@loop:\nRTN\nnext:\n\@\@loop:\nRTN",
    'LOCALS @@', 'NOLOCALS @@', 'LOCALS extra', 'NOLOCALS extra',
  ) {
    my $success = eval {
      Parser::HPC->new->from_string(
        "MODEL P35S\nSEGMENT CODE\n$code\nENDS\nEND\n"
      );
      1;
    };
    ok( !$success, "$code is rejected" );
  }
};

done_testing;