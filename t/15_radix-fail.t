use strict;
use warnings;

use Test::More;
use Parser::HPC;

subtest 'RADIX rejects unsupported syntax and invalid values' => sub {
  for my $code (
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
        "MODEL P35S\nSEGMENT CODE\n$code\nENDS\nEND\n"
      );
      1;
    };
    ok( !$success, "$code is rejected" );
  }
};

subtest 'RADIX directive spelling is case-sensitive' => sub {
  for my $directive ( 'radix 16', 'Radix 16', 'RaDiX 16' ) {
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

subtest 'uppercase E is not a decimal exponent in numeric values' => sub {
  for my $source (
    "MODEL P35S\nSEGMENT DATA\nVALUE EQU 1E-3\nENDS\nEND\n",
    "MODEL P35S\nSEGMENT STACK\nREGX SET 1E-3\nENDS\nEND\n",
  ) {
    my $success = eval { Parser::HPC->new->from_string($source); 1 };
    ok( !$success, 'uppercase E exponent is rejected' );
  }
};

subtest 'non-decimal RADIX rejects unsuffixed decimal floats' => sub {
  for my $base ( 2, 8, 16 ) {
    for my $segment ( 'DATA', 'STACK' ) {
      my $statement = $segment eq 'DATA'
        ? 'VALUE EQU 7e-1' : 'REGX SET 7e-1';
      my $source = "MODEL P35S\nSEGMENT $segment\n"
        . "RADIX $base\n$statement\nENDS\nEND\n";
      my $success = eval { Parser::HPC->new->from_string($source); 1 };
      ok( !$success, "RADIX $base rejects $segment float value" );
    }
  }
};

done_testing;
