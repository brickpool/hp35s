use strict;
use warnings;

use Test::More;
use Parser::HPC;

subtest 'unknown statement fails after both alternatives' => sub {
  for my $code ( 'UNKNOWN', '?' ) {
    my $parser = Parser::HPC->new;
    my $source = <<ASM;
; Unknown statement inside a declared code segment
IDEAL
P35S
MODEL TINY
CODESEG
start:
  LBL C
  $code ; neither an instruction nor a literal
  RTN
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
IDEAL
P35S
MODEL TINY
CODESEG
start:
  LBL C
  $code

  ; The next statement must remain separate
  STOP
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
    [ 'FIX', qr/Illegal number/ ],
    [ 'STO', qr/Expected variable/ ],
    [ 'eqn', qr/Expected expression/ ],
  );
  for my $case ( @cases ) {
    my ($code, $message) = @$case;
    my $parser = Parser::HPC->new;
    my $success = eval {
      $parser->from_string(
        "IDEAL\nP35S\nMODEL TINY\n\nCODESEG\n$code\n\nEND\n"
      );
      1;
    };
    my $error = "$@";
    ok( !$success, "$code fails" );
    like( $error, $message, 'specific diagnostic preserved' );
  }
};

subtest 'empty EQU string fails' => sub {
  my $parser = Parser::HPC->new;
  my $success = eval {
    $parser->from_string(<<'ASM');
IDEAL
P35S
MODEL TINY
DATASEG
EMPTY EQU ""
END
ASM
    1;
  };
  my $error = "$@";
  ok( !$success, 'empty EQU string is rejected' );
  like( $error, qr/Need expression/, 'empty value reports missing expression' );
};

subtest 'legacy segment and MASM simplified syntax are rejected' => sub {
  for my $source (
    "IDEAL\nP35S\nMODEL TINY\nSEGMENT CODE\nRTN\nENDS\nEND\n",
    "IDEAL\nP35S\nMODEL TINY\nCODESEG\nRTN\nENDS\nEND\n",
    "IDEAL\nP35S\nMODEL TINY\n.DATA\n.CODE\n.STACK 4\nEND\n",
  ) {
    my $success = eval { Parser::HPC->new->from_string($source); 1 };
    ok( !$success, 'unsupported segment spelling is rejected' );
  }
};

done_testing;