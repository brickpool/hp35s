use strict;
use warnings;

use Test::More;
use Parser::HPC;

subtest 'DISPLAY emits messages without changing parsed code' => sub {
  my $parser = Parser::HPC->new;
  my (@warnings, $root);
  {
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    $root = $parser->from_string(<<'ASM');
IDEAL
P35S
MODEL TINY
DISPLAY 'Starting assembly'
CODESEG
  RTN
  DISPLAY 'Inside code'
  DISPLAY "Assembly complete"
END
ASM
  }

  my @messages = ( 'Starting assembly', 'Inside code', 'Assembly complete' );
  is( scalar @warnings, scalar @messages, 'one warning is emitted per message' );
  for my $index ( 0 .. $#messages ) {
    like( $warnings[$index], qr/\A\Q$messages[$index]\E(?:\s|\z)/,
      "message $index is warned in source order" );
  }
  is( scalar @{ $root->{segments} }, 1, 'DISPLAY produces no segment nodes' );
  is_deeply( $root->{segments}->[0]->{statements}, [
    { instruction => { value => 'RTN' } },
  ], 'messages are not stored as code statements' );
  ok( !exists $root->{display}, 'messages are not stored in the parse AST' );
};

subtest 'DISPLAY reports string errors at the source position' => sub {
  my @cases = (
    [ "IDEAL\nP35S\nMODEL TINY\nDISPLAY \nCODESEG\nRTN\n\nEND\n",
      qr/Need quoted string on line 4/, 
      'missing message' ],
    [ "IDEAL\nP35S\nMODEL TINY\nDISPLAY \"unfinished\nCODESEG\nRTN\n\nEND\n",
      qr/Need quoted string on line 4/, 
      'unterminated message' ],
    [ "IDEAL\nP35S\nMODEL TINY\nDISPLAY ''\nCODESEG\nRTN\n\nEND\n",
      qr/Need quoted string on line 4/, 
      'empty message' ],
    [ "MODEL TINY\nCODESEG\nRTN\nDISPLAY 123\nEND\n",
      qr/Need quoted string on line 4/, 
      'invalid message after an instruction' ],
    [ "MODEL TINY\nCODESEG\nDISPLAY ''\nRTN\nEND\n",
      qr/Need quoted string on line 3/, 
      'empty message inside code' ],
    [ "IDEAL\nP35S\nMODEL TINY\nDISPLAY \"I\/O\nLibrary\"\nCODESEG\nRTN\n\nEND",
      qr/Missing end quote on line 4 at:\nDISPLAY \"I\/O\n {12}\^/,
      'newline in message after I/O' ],
  );
  for my $case (@cases) {
    my ($source, $message, $description) = @$case;
    my $success = eval { Parser::HPC->new->from_string($source); 1 };
    my $error = "$@";
    ok( !$success, "$description is rejected" );
    like( $error, $message, "$description reports the expected error" );
  }
};

subtest 'DISPLAY cannot share a line with the next directive' => sub {
  my @cases = (
    [ 'between segments',
      "IDEAL\nP35S\nMODEL TINY\nDISPLAY 'message' CODESEG\nRTN\n\nEND\n" ],
    [ 'inside code',
      "IDEAL\nP35S\nMODEL TINY\nCODESEG\nDISPLAY 'message' RTN\n\nEND\n" ],
  );
  for my $case (@cases) {
    my ($context, $source) = @$case;
    my (@warnings, $success, $error);
    {
      local $SIG{__WARN__} = sub { push @warnings, @_ };
      $success = eval { Parser::HPC->new->from_string($source); 1 };
      $error = "$@";
    }
    ok( !$success, "DISPLAY cannot share a line $context" );
    like( $error, qr/Extra characters on line/, "$context reports line error" );
    is_deeply( \@warnings, [], "invalid DISPLAY $context emits no message" );
  }
};

subtest 'DISPLAY allows uppercase spelling' => sub {
  local $SIG{__WARN__} = sub { ::note @_ if $ENV{AUTHOR_TESTING}};
  for my $directive ( 'display', 'DiSpLaY' ) {
    my $source = <<ASM;
IDEAL
P35S
MODEL TINY
$directive 'message'
CODESEG
  RTN
END
ASM
    my $success = eval { Parser::HPC->new->from_string($source); 1 };
    ok( $success, "$directive is allowed" );
  }
};

done_testing;
