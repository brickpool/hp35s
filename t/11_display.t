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
MODEL P35S
DISPLAY 'Starting assembly'
SEGMENT CODE
  RTN
  DISPLAY 'Inside code'
  ENDS
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
    [ "MODEL P35S\nDISPLAY \nSEGMENT CODE\nRTN\nENDS\nEND\n",
      qr/Need quoted string on line 2/, 'missing message' ],
    [ "MODEL P35S\nDISPLAY \"I\/O\nLibrary\"\nSEGMENT CODE\nRTN\nENDS\nEND\n",
      qr/Missing end quote on line 2 at:\nDISPLAY \"I\/O\n {12}\^/,
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
      "MODEL P35S\nDISPLAY 'message' SEGMENT CODE\nRTN\nENDS\nEND\n" ],
    [ 'inside code',
      "MODEL P35S\nSEGMENT CODE\nDISPLAY 'message' RTN\nENDS\nEND\n" ],
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
MODEL P35S
$directive 'message'
SEGMENT CODE
  RTN
ENDS
END
ASM
    my $success = eval { Parser::HPC->new->from_string($source); 1 };
    ok( $success, "$directive is allowed" );
  }
};

done_testing;
