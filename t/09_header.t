use strict;
use warnings;

use Test::More;
use Parser::HPC;

sub parse_header {
  my ($header) = @_;
  return Parser::HPC->new->from_string(<<ASM);
$header
CODESEG
  RTN
END
ASM
}

subtest 'IDEAL header separates language and memory model' => sub {
  my $root = parse_header(<<'ASM');
; header test
  IDEAL
  P35S
  MODEL TINY
ASM
  is( $root->{language}, 'P35S', 'language is P35S' );
  is( $root->{model}, 0, 'TINY is represented by model number zero' );
  is_deeply( $root->{segments}->[0]->{statements}, [
    { instruction => { value => 'RTN' } },
  ], 'header does not produce statements' );
};

subtest 'mode is optional and recognizes IDEAL and MASM' => sub {
  for my $mode ( 
    '', 
    'IDEAL', 
    'MASM',
  ) {
    my $root = parse_header(<<ASM);
; model test
  ${mode}
  P35S
  MODEL TINY
ASM
    is( $root->{language}, 'P35S', "header parses with mode [$mode]" );
  }
};

subtest 'header permits title, comments and whitespace' => sub {
  my $root = parse_header(<<'ASM');
%TITLE "Header test"
  ; mode
  IDEAL       ; only supported mode
  P35S        ; language
  MODEL	TINY  ; memory model
ASM
  is( $root->{title}, 'Header test', 'optional title is retained' );
  is( $root->{language}, 'P35S', 'language survives whitespace and comments' );
  is( $root->{model}, 0, 'model number zero survives whitespace and comments' );
};

subtest 'language is optional' => sub {
  my $root = parse_header("IDEAL\nMODEL TINY");
  is( $root->{language}, 'P35S', 'header is valid without P35S' );
  is( $root->{model}, 0, 'TINY is retained without P35S' );
};

subtest 'header permits directives after MODEL' => sub {
  my $root = parse_header(<<ASM);
; permitted any order of header directives
  IDEAL
  MODEL TINY
  P35S
  \%TITLE "Header test"
ASM
  is( $root->{model}, 0, 'MODEL may precede the other header directives' );
  is( $root->{language}, 'P35S', 'P35S is accepted after MODEL' );
  is( $root->{title}, 'Header test', 'title is accepted after MODEL' );
};

subtest 'scope preserves committed parser errors' => sub {
  my $success = eval {
    parse_header(<<ASM);
IDEAL
P35S
MODEL TINY extra
ASM
    1;
  };
  my $error = "$@";
  ok( !$success, 'malformed directive is rejected' );
  like(
    $error,
    qr/Extra characters/,
    'committed inner error survives header scope'
  );
};

subtest 'header rejects unsupported and malformed forms' => sub {
  my @cases = (
    [ '', 
      qr/Model must be specified first/, 
      'empty header' ],
    [ 'MODEL P35S', 
      qr/Invalid model type/, 
      'language used as model' ],
    [ "IDEAL\nP42S\nMODEL TINY",
      qr/Illegal instruction/,
      'unsupported language' ],
    [  "IDEAL\nP35S", 
      qr/Model must be specified first/, 
      'missing MODEL' ],
    [ "IDEAL\nP35S\nMODEL SMALL",
      qr/Invalid model type/,
      'unsupported model' ],
    [ "IDEAL\nP35S\nMODEL",
      qr/Invalid model type/,
      'missing model argument' ],
    [ "IDEAL\nP35S\nMODEL \nTINY",
      qr/Invalid model type/,
      'model argument on next line' ],
    [ "IDEAL P35S\nMODEL TINY",
      qr/Extra characters/,
      'mode and language on one line' ],
    [ "IDEAL\nP35S MODEL TINY",
      qr/Extra characters/,
      'language and model on one line' ],
    [ "IDEAL\nP35S\nMODEL TINY extra",
      qr/Extra characters/,
      'extra model argument' ],
    [ "IDEAL\nP35SX\nMODEL TINY",
      qr/Illegal instruction/,
      'language prefix' ],
    [ "IDEAL\nP35S\nMODEL TINYextra",
      qr/Invalid model type/,
      'model prefix' ],
  );
  for my $case (@cases) {
    my ($header, $message, $description) = @$case;
    my $success = eval { parse_header($header); 1 };
    my $error = "$@";
    ok( !$success, "$description is rejected" );
    like( $error, $message, "$description reports the expected error" );
  }
};

done_testing;