use strict;
use warnings;

use Test::More;
use Parser::HPC;

subtest '@@labels are enabled by default and scoped by nonlocal labels' => sub {
  my $root = Parser::HPC->new->from_string(<<'ASM');
MODEL TINY
CODESEG
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
END start
ASM

  my $statements = $root->{segments}->[0]->{statements};
  my $first = $statements->[2]->{instruction}->{operand}->{value};
  my $second = $statements->[7]->{instruction}->{operand}->{value};

  like( $first,  qr/^\@\@\d{4}$/, 'first local uses internal label form' );
  like( $second, qr/^\@\@\d{4}$/, 'second local uses internal label form' );

  isnt( $first, $second, 'same local spelling has distinct scoped identities' );
  is( $statements->[5]->{instruction}->{operand}->{value}, $first,
    'case-insensitive reference retains first scope' );
  is( $statements->[10]->{instruction}->{operand}->{value}, $second,
    'reference retains second scope' );
  is_deeply( $statements->[3], { label => { name => $first } },
    'first local declaration' );
  is_deeply( $statements->[8], { label => { name => $second } },
    'second local declaration' );
};

subtest 'NOLOCALS disables qualification and LOCALS enables it again' => sub {
  my $root = Parser::HPC->new->from_string(<<'ASM');
MODEL TINY
CODESEG
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
END @@loop
ASM

  my $statements = $root->{segments}->[0]->{statements};
  my $global_def = $statements->[3]{label}{name};
  my $global_ref = $statements->[4]{instruction}{operand}{value};
  my $next_ref   = $statements->[6]{instruction}{operand}{value};
  my $local_def  = $statements->[7]{label}{name};
  my $local_ref  = $statements->[8]{instruction}{operand}{value};

  is( $global_def, '@@LOOP',
    'NOLOCALS keeps double-at declaration global' );
  is( $global_ref, $global_def,
    'NOLOCALS reference resolves to global declaration' );
  is( $next_ref, $global_def,
    'nonlocal label does not change global double-at identity' );
  like( $local_def, qr/^\@\@\d{4}$/,
    'LOCALS creates an internal local identity' );
  is( $local_ref, $local_def,
    'LOCALS reference resolves to local declaration' );
  isnt( $local_def, $global_def,
    'local and global double-at identities are distinct' );
};

subtest 'local scope follows nonlocal labels' => sub {
  my $root = Parser::HPC->new->from_string(<<'ASM');
MODEL TINY
CODESEG
@@initial:
  GTO @@initial
start:
  GTO @@target
NOLOCALS
LOCALS
CODESEG
@@target:
  RTN
END
ASM

  my $statements = $root->{segments}->[0]->{statements};
  my $initial = $statements->[1]->{instruction}->{operand}->{value};
  my $target = $statements->[3]->{instruction}->{operand}->{value};

  is_deeply( $statements->[0], { label => { name => $initial } },
    'locals before a nonlocal label use the initial scope' );
  is_deeply( $statements->[4], { label => { name => $target } },
    'section and LOCALS changes do not start a new scope' );
};

subtest 'only double-at names are local' => sub {
  my $root = Parser::HPC->new->from_string(<<'ASM');
MODEL TINY
CODESEG
start:
@@A001:
  RTN
  GTO @@A001
@shared:
  RPN
next:
  GTO @@A001
  GTO @shared
END start
ASM

  my $statements = $root->{segments}->[0]->{statements};
  my $local = $statements->[3]->{instruction}->{operand};

  is( $local->{type}, 'label', '@@A001 is not a calculator address' );
  like( $local->{value}, qr/^\@\@\d{4}$/,
    'double-at label gets an internal local identity' );
  is( $statements->[1]{label}{name}, $local->{value},
    'double-at reference resolves to its declaration' );
  is( $statements->[8]{instruction}{operand}{value}, '@SHARED',
    'single-at name remains global' );
};

done_testing;
