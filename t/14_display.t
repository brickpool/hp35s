use strict;
use warnings;

use Test::More;
use Parser::HPC;
use lib 't/lib';
use FrontendTest qw( run_frontend );

subtest 'DISPLAY directives emit quoted messages without changing code AST' => sub {
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

  is_deeply( \@warnings, [
    "Starting assembly\n", "Inside code\n", "Assembly complete\n",
  ], 'messages are warned in source order while parsing' );
  ok( !exists $root->{display}, 'messages are not stored in the parse AST' );
  is_deeply( $root->{segments}->{_TEXT}->{statements}, [
    { instruction => { value => 'RTN' } },
  ], 'DISPLAY directives are not code statements' );
};

subtest 'DISPLAY is emitted before a later parse error' => sub {
  my $parser = Parser::HPC->new;
  my @warnings;
  my $success;
  {
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    $success = eval {
      $parser->from_string(
        "MODEL P35S\nDISPLAY 'Checkpoint'\nSEGMENT CODE\nUNKNOWN\nENDS\nEND\n"
      );
      1;
    };
  }
  ok( !$success, 'later invalid code still fails parsing' );
  is_deeply( \@warnings, [ "Checkpoint\n" ],
    'message is emitted before the parser reports the later failure' );
};

subtest '%OUT remains unsupported' => sub {
  my $parser = Parser::HPC->new;
  my $success = eval {
    $parser->from_string(
      "MODEL P35S\n%OUT This message is not supported\nSEGMENT CODE\nRTN\nENDS\nEND\n"
    );
    1;
  };
  ok( !$success, '%OUT is rejected rather than treated as DISPLAY' );
};

subtest 'DISPLAY writes messages to STDERR without changing the listing' => sub {
  my $source = <<'ASM';
MODEL P35S
DISPLAY 'Assembly started'
SEGMENT CODE
RTN
ENDS
END
ASM
  my ($status, $output, $errors) = run_frontend($source);
  is( $status, 0, 'frontend accepts DISPLAY' );
  is( $errors, "Assembly started\n", 'message is displayed on STDERR' );
  unlike( $output, qr/Assembly started/, 'message is not part of HP output' );
};

done_testing;