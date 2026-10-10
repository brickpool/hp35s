use strict;
use warnings;

use Test::More;
use Parser::HPC;

subtest 'unknown statement fails after both alternatives' => sub {
  for my $code ( 'UNKNOWN', '?' ) {
    my $parser = Parser::HPC->new;
    my $source = <<ASM;
; Unknown statement inside a declared code segment
MODEL P35S
SEGMENT main CODE
start:
  LBL C
  $code ; neither an instruction nor a literal
  RTN
ENDS main
END start
ASM
    my $success = eval { $parser->from_string($source); 1 };
    my $error = "$@";
    ok( !$success, "$code rejects the complete program" );
    like( $error, qr/Illegal instruction/,
      'statement fallback reports the assembler diagnostic' );
    unlike( $error, qr/Found nothing parseable|Expected any of/,
      'token alternative diagnostics do not escape' );
  }
};

subtest 'statement line boundary rejects extra tokens' => sub {
  for my $code (
    'RTN extra   ; return',
    '0 extra   ; zero',
    '12.3d',
    '1e3d',
    'pi extra   ; constant',
    'GTO start extra   ; jump',
    'RTN RTN',
    '0 1',
  ) {
    my $parser = Parser::HPC->new;
    my $source = <<ASM;
; One statement per line; comments and whitespace are permitted
MODEL P35S
SEGMENT main CODE
start:
  LBL C
  $code

  ; The next statement must remain separate
  STOP
ENDS main
END start
ASM
    my $success = eval { $parser->from_string($source); 1 };
    my $error = "$@";
    ok( !$success, "$code rejects extra tokens" );
    like( $error, qr/Extra characters on line/,
      'recognized statement reaches the line-boundary diagnostic' );
    unlike( $error, qr/Illegal instruction/,
      'recognized statement does not fall back to unknown instruction' );
  }
};

subtest 'parse failures' => sub {
  my @cases = (
    [ 'GTO', qr/Illegal origin address/ ],
    [ 'LBL', qr/Expected variable/ ],
    [ 'FIX', qr/Expected number/ ],
    [ 'STO', qr/Expected variable/ ],
    [ 'eqn', qr/Expected expression/ ],
  );
  for my $case ( @cases ) {
    my ($code, $message) = @$case;
    my $parser = Parser::HPC->new;
    my $success = eval {
      $parser->from_string(
        "MODEL P35S\n\nSEGMENT CODE\n$code\nENDS\nEND\n"
      );
      1;
    };
    my $error = "$@";
    ok( !$success, "$code fails" );
    like( $error, $message, 'specific diagnostic preserved' );
  }
};

done_testing;