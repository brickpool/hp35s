use strict;
use warnings;

use Test::More;
use Parser::HPC;

my $source = <<'ASM';
IDEAL
P35S
MODEL TINY
RADIX 16
STACK
  REGX SET 1
  RADIX 16
  REGX SET 2
  REGY SET 100
DATASEG
  SIZE EQU 1
CODESEG
start:
  RTN
STACK
  REGZ SET FFh
  REGX SET 3
END start
ASM

subtest 'SET is collected only from STACK sections' => sub {
  my $root = Parser::HPC->new->from_string($source);
  my ($stack) = grep { $_->{type} eq 'stack' } @{ $root->{segments} };
  is_deeply( $stack, {
    name => 'STACK',
    type => 'stack',
    assignments => {
      REGX => { type => 'register', value => 3 },
      REGY => { type => 'register', value => 256 },
      REGZ => { type => 'register', value => 'FFh' },
    },
  }, 'multiple STACK sections aggregate radix-aware SET values' );
  ok( !exists $root->{stack_size}, 'STACK does not define size metadata' );
  my ($code) = grep { $_->{type} eq 'code' } @{ $root->{segments} };
  is( scalar @{ $code->{statements} }, 2,
    'code statements are unaffected by STACK sections' );
};

subtest 'SET is rejected outside STACK sections' => sub {
  my @invalid = (
    <<'ASM',
IDEAL
P35S
MODEL TINY
  REGX SET nope
CODESEG
  RTN
END
ASM
    <<'ASM',
IDEAL
P35S
MODEL TINY
DATASEG
  REGX SET 1
END
ASM
    <<'ASM',
IDEAL
P35S
MODEL TINY
CODESEG
  REGX SET 1
END
ASM
  );
  for my $source ( @invalid ) {
    my $result = eval { Parser::HPC->new->from_string($source); 1 };
    ok( !$result, 'SET outside STACK is rejected' );
  }
};

subtest 'STACK requires SET before its value' => sub {
  my $invalid = <<'ASM';
IDEAL
P35S
MODEL TINY
STACK
  REGX 2
END
ASM
  my $result = eval { Parser::HPC->new->from_string($invalid); 1 };

  ok( !$result, 'malformed STACK statement is rejected' );
  like( $@, qr/Expecting segment or group quantity/, 
    'reports that SET was expected' );
};

done_testing;
