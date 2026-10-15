use strict;
use warnings;

use Test::More;
use Parser::HPC;
use lib 't/lib';
use FrontendTest qw( run_frontend );

subtest 'local labels are enabled by default and scoped by nonlocal labels' => sub {
  my $source = <<'ASM';
MODEL P35S
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
  my $statements = $root->{segments}->[0]->{statements};
  is( scalar @$statements, 11, 'seven instructions and four declarations, no LOCALS node' );
  my $first = $statements->[2]->{instruction}->{operand}->{value};
  my $second = $statements->[7]->{instruction}->{operand}->{value};
  isnt( $first, $second, 'same local spelling has distinct scoped identities' );
  is( $statements->[5]->{instruction}->{operand}->{value}, $first,
    'case-insensitive backward reference retains first scope' );
  is( $statements->[10]->{instruction}->{operand}->{value}, $second,
    'backward reference retains second scope' );
  is_deeply( $statements->[3], { label => { name => $first } }, 'first local declaration' );
  is_deeply( $statements->[8], { label => { name => $second } }, 'second local declaration' );
  for my $options ( [], [ '-j' ], [ '-s' ] ) {
    my ($first_scope, $next_scope) = split /(?=^next:)/m, $source;
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
  my $statements = $root->{segments}->[0]->{statements};
  is( scalar @$statements, 9, 'four instructions and five declarations, no directive nodes' );
  is( $statements->[4]->{instruction}->{operand}->{value}, '@@LOOP',
    'disabled local name remains global' );
  is( $statements->[6]->{instruction}->{operand}->{value}, '@@LOOP',
    'nonlocal label does not restrict ordinary global reference' );
  is_deeply( $statements->[3], { label => { name => '@@LOOP' } },
    'global declaration is retained' );
  is_deeply( $root->{startaddr}, {
    type => 'label', value => $statements->[8]->{instruction}->{operand}->{value},
  },
    'END resolves a local label in the current scope' );
};

subtest 'local scope follows labels rather than segments or directives' => sub {
  my $root = Parser::HPC->new->from_string(<<'ASM');
MODEL P35S
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
  my $target = $root->{segments}->[0]->{statements}->[3]
    ->{instruction}->{operand}->{value};
  is_deeply( $root->{segments}->[1]->{statements}->[0],
    { label => { name => $target } },
    'segment and mode changes do not start a new scope' );
  my $initial = $root->{segments}->[0]->{statements}->[1]
    ->{instruction}->{operand}->{value};
  is_deeply( $root->{segments}->[0]->{statements}->[0],
    { label => { name => $initial } },
    'locals before the first nonlocal label have an initial scope' );
};

subtest 'only double-at prefixes are local and references do not escape scope' => sub {
  my $root = Parser::HPC->new->from_string(<<'ASM');
MODEL P35S
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
  my $statements = $root->{segments}->[0]->{statements};
  my $local = $statements->[3]->{instruction}->{operand};
  is( $local->{type}, 'label', '@@A001 is not a literal calculator address' );
  is_deeply( $statements->[1], { label => { name => $local->{value} } },
    'address-like local name resolves normally' );
  my $other = $statements->[7]->{instruction}->{operand}->{value};
  ok( !(grep { $_->{label} && $_->{label}->{name} eq $other } @$statements),
    'reference in another scope does not resolve to earlier local definition' );
  is( $statements->[8]->{instruction}->{operand}->{value}, '@SHARED',
    'single-at name remains global under LOCALS' );
};

subtest 'LOCALS and NOLOCALS allow uppercase spelling' => sub {
  for my $directive ( 'locals', 'Locals', 'nolocals', 'Nolocals' ) {
    for my $source (
      "MODEL P35S\n$directive\nSEGMENT CODE\nRTN\nENDS\nEND\n",
      "MODEL P35S\nSEGMENT CODE\n$directive\nRTN\nENDS\nEND\n",
      "MODEL P35S\nSEGMENT DATA\n$directive\nVALUE EQU 1\nENDS\nEND\n",
      "MODEL P35S\nSEGMENT STACK\n$directive\nREGX SET 1\nENDS\nEND\n",
    ) {
      my $success = eval { Parser::HPC->new->from_string($source); 1 };
      ok( $success, "$directive is allowed" );
    }
  }
};

subtest 'duplicate locals and unsupported directive parameters are rejected' => sub {
  for my $code (
    "start:\n\@\@loop:\nRTN\n\@\@loop:\nRTN",
    "NOLOCALS\nstart:\n\@\@loop:\nRTN\nnext:\n\@\@loop:\nRTN",
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
