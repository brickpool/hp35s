use strict;
use warnings;

use Test::More;
use Parser::HPC;

subtest 'RADIX rejects unsupported syntax and invalid values' => sub {
  for my $code (
    'RADIX', 'RADIX16', 'RADIX 7', 'RADIX 8 1', 'RADIX "8"', '.RADIX',
    'RADIX 3', 'RADIX 0', 'RADIX 17', 'RADIX -2',
    'RADIX 10h', 'RADIX 16 extra', "RADIX\n16",
    'RADIX. 16', 'RADIX, 16',
    '.RADIX 16', "RADIX 2\n102", "RADIX 8\n89",
    "RADIX 16\n12G", "RADIX 16\n12ab",
    "RADIX 16\n12H", "RADIX 16\n-125h", "RADIX 10\n12D",
    "RADIX 10\n101B", "RADIX 10\n12O", "RADIX 10\n1E-3",
    "RADIX 10\n-1b", "RADIX 10\n-1o", "RADIX 10\n-1h",
    "RADIX 2\nCF 11b", "RADIX 8\nFIX 11o", "RADIX 16\nSF 0Bh",
  ) {
    my $parser = Parser::HPC->new;
    my $success = eval {
      $parser->from_string(
        "IDEAL\nP35S\nMODEL TINY\nCODESEG\n$code\n\nEND\n"
      );
      1;
    };
    ok( !$success, "$code is rejected" );
  }
};

subtest 'invalid RADIX base reports the documented error' => sub {
  my $success = eval {
    Parser::HPC->new->from_string(
      "IDEAL\nP35S\nMODEL TINY\nCODESEG\nRADIX 7\n\nEND\n"
    );
    1;
  };
  my $error = "$@";
  ok( !$success, 'RADIX 7 is rejected' );
  like( $error, qr/Illegal radix/, 'the diagnostic says Illegal radix' );
};

subtest 'uppercase E is not a decimal exponent in numeric values' => sub {
  for my $source (
    "IDEAL\nP35S\nMODEL TINY\nDATASEG\nVALUE EQU 1E-3\n\nEND\n",
    "IDEAL\nP35S\nMODEL TINY\nSTACK\nREGX SET 1E-3\nEND\n",
  ) {
    my $success = eval { Parser::HPC->new->from_string($source); 1 };
    ok( !$success, 'uppercase E exponent is rejected' );
  }
};

subtest 'non-decimal RADIX rejects unsuffixed decimal floats' => sub {
  for my $base ( 2, 8, 16 ) {
    for my $area ( 'data', 'stack' ) {
      my $source = $area eq 'data'
        ? "IDEAL\nP35S\nMODEL TINY\nDATASEG\nRADIX $base\nVALUE EQU 7e-1\n\nEND\n"
        : "IDEAL\nP35S\nMODEL TINY\nRADIX $base\nSTACK\nREGX SET 7e-1\nEND\n";
      my $success = eval { Parser::HPC->new->from_string($source); 1 };
      ok( !$success, "RADIX $base rejects $area float value" );
    }
  }
};

done_testing;
