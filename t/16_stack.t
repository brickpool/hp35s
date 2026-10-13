use strict;
use warnings;

use Test::More;
use Parser::HPC;

my $source = <<'ASM';
MODEL P35S
SEGMENT CODE
start:
  RTN
ENDS
SEGMENT STACK
  REGX  SET 2
  RADIX 16
  REGY  SET 100
  REGZ  SET FFh
  REGX  SET 3
ENDS
END start
ASM

subtest 'STACK assignments parse in a minimal program' => sub {
  my $root = Parser::HPC->new->from_string($source);
  my ($segment) = grep { $_->{type} eq 'stack' } @{ $root->{segments} };

  is_deeply( $segment, {
    name => 'STACK',
    type => 'stack',
    assignments => {
      REGX => { type => 'register', value => 3 },
      REGY => { type => 'register', value => 256 },
      REGZ => { type => 'register', value => 'FFh' },
    },
  }, 'parses radix-aware SET values and keeps the last register assignment' );
};

subtest 'STACK requires SET before its value' => sub {
  my $invalid = <<'ASM';
MODEL P35S
SEGMENT STACK
  REGX  2
ENDS
END
ASM
  my $result = eval { Parser::HPC->new->from_string($invalid); 1 };

  ok( !$result, 'malformed stack assignment is rejected' );
  like( $@, qr/Expecting segment or group quantity/,
    'reports that SET was expected' );
};

done_testing;
