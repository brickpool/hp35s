use strict;
use warnings;

use Test::More;
use Test::Exception;
use Parser::HPC;

{
  package ParserTest;
  use parent 'Parser::HPC';

  sub parse {
    my $self = shift;

    my $header = $self->parse_header;

    $self->{header_end_pos} = $self->pos;
    $self->expect(qr/(?:DATASEG|CODESEG|STACK|END)\b/i);

    return $header;
  }

  $INC{'ParserTest.pm'} = 1;
}

use_ok 'ParserTest';

subtest 'header combines directive results' => sub {
  my $source = <<'ASM';
%TITLE "I/O Library"
MASM
P35S
MODEL TINY
CODESEG
ASM

  my $parser = ParserTest->new();

  is_deeply(
    $parser->from_string($source),
    {
      title    => 'I/O Library',
      mode     => 'MASM',
      language => 'P35S',
      model    => 0,
    },
    'header combines directive results',
  );

  is(
    $parser->{header_end_pos},
    index($source, 'CODESEG'),
    'header ends before CODESEG',
  );
};

subtest 'state directives are applied but omitted from the header' => sub {
  my $source = <<'ASM';
MODEL TINY
RADIX 16
NOLOCALS
CODESEG
ASM

  my $parser = ParserTest->new();

  is_deeply(
    $parser->from_string($source),
    { model => 0 },
    'state directives are omitted from the header',
  );

  is( $parser->{radix}, 16, 'RADIX changes parser state' );
  is( $parser->{locals}, 0, 'NOLOCALS changes parser state' );
};

subtest 'DISPLAY is applied but omitted from the header' => sub {
  my $source = <<'ASM';
DISPLAY "Starting assembly"
MODEL TINY
CODESEG
ASM

  my $parser = ParserTest->new();
  my @warnings;

  {
    local $SIG{__WARN__} = sub { push @warnings, @_ };

    is_deeply(
      $parser->from_string($source),
      { model => 0 },
      'DISPLAY is omitted from the header',
    );
  }

  is( scalar @warnings, 1, 'DISPLAY emits one warning' );
  like(
    $warnings[0],
    qr/\AStarting assembly(?:\s|\z)/,
    'DISPLAY emits its message',
  );
};

subtest 'header stops before section terminators' => sub {
  for my $terminator ( qw(DATASEG CODESEG STACK END) ) {
    my $source = "MODEL TINY\n$terminator\n";
    my $parser = ParserTest->new();

    is_deeply(
      $parser->from_string($source),
      { model => 0 },
      "$terminator terminates the header",
    );

    is(
      $parser->{header_end_pos},
      index($source, $terminator),
      "header ends before $terminator",
    );
  }
};

subtest 'header requires MODEL' => sub {
  my $source = "IDEAL\nP35S\nCODESEG\n";
  my $parser = ParserTest->new();

  throws_ok {
    $parser->from_string($source);
  } qr/Model must be specified first/,
    'missing MODEL is rejected';

  is( $@->{pos}, index( $source, 'CODESEG' ), 'failure position', );
};

subtest 'header currently accepts only TINY model' => sub {
  for my $model ( qw(SMALL COMPACT MEDIUM LARGE HUGE) ) {
    my $source = "MODEL $model\nCODESEG\n";
    my $parser = ParserTest->new();

    throws_ok {
      $parser->from_string($source);
    } qr/Invalid model type/,
      "$model is rejected by the header";

    is( $@->{pos}, index( $source, 'CODESEG' ), 'failure position', );
  }
};

subtest 'header rejects unknown instructions' => sub {
  my $source = "UNKNOWN\nMODEL TINY\nCODESEG\n";
  my $parser = ParserTest->new();

  throws_ok {
    $parser->from_string($source);
  } qr/Illegal instruction/,
    'unknown header instruction is rejected';

  is( $@->{pos}, 0, 'failure position' );
};

done_testing;
