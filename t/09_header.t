use strict;
use warnings;

use Test::More;
use Parser::HPC;

sub parse_header {
  my ($header) = @_;
  return Parser::HPC->new->from_string(
    "$header\nCODESEG\nRTN\n\nEND\n"
  );
}

subtest 'IDEAL header separates language and memory model' => sub {
  my $root = parse_header("IDEAL\nP35S\nMODEL TINY");
  is( $root->{language}, 'P35S', 'language is P35S' );
  is( $root->{model}, 0, 'TINY is represented by model number zero' );
  is_deeply( $root->{segments}->[0]->{statements}, [
    { instruction => { value => 'RTN' } },
  ], 'header does not produce statements' );
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

subtest 'header rejects unsupported forms and incorrect ordering' => sub {
  my @cases = (
    [ 'MODEL P35S',       qr/IDEAL must be specified first/, 'legacy header' ],
    [ "P35S\nMODEL TINY", qr/IDEAL must be specified first/, 'missing IDEAL' ],
    [
      "IDEAL\nMODEL TINY",
      qr/Missing or illegal language ID/,
      'missing language'
    ],
    [
      "IDEAL\nP42S\nMODEL TINY",
      qr/Missing or illegal language ID/,
      'unsupported language'
    ],
    [ "IDEAL\nP35S", qr/MODEL must follow language ID/, 'missing MODEL' ],
    [
      "IDEAL\nP35S\nMODEL SMALL",
      qr/Missing or illegal model ID/,
      'unsupported model'
    ],
    [
      "IDEAL\nP35S\nMODEL",
      qr/MODEL must follow language ID/,
      'missing model argument'
    ],
    [
      "IDEAL\nP35S\nMODEL \nTINY",
      qr/Missing or illegal model ID/,
      'model argument on next line'
    ],
    [
      "IDEAL P35S\nMODEL TINY",
      qr/Extra characters/,
      'mode and language on one line'
    ],
    [
      "IDEAL\nP35S MODEL TINY",
      qr/Extra characters/,
      'language and model on one line'
    ],
    [
      "IDEAL\nP35S\nMODEL TINY extra",
      qr/Extra characters/,
      'extra model argument'
    ],
    [
      "IDEAL\nP35SX\nMODEL TINY",
      qr/Missing or illegal language ID/,
      'language prefix'
    ],
    [
      "IDEAL\nP35S\nMODEL TINYextra",
      qr/Missing or illegal model ID/,
      'model prefix'
    ],
    [
      "ideal\nP35S\nMODEL TINY",
      qr/IDEAL must be specified first/,
      'lowercase mode'
    ],
    [
      "IDEAL\np35s\nMODEL TINY",
      qr/Missing or illegal language ID/,
      'lowercase language'
    ],
    [
      "IDEAL\nP35S\nmodel TINY",
      qr/MODEL must follow language ID/,
      'lowercase directive'
    ],
    [
      "IDEAL\nP35S\nMODEL tiny",
      qr/Missing or illegal model ID/,
      'lowercase model'
    ],
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