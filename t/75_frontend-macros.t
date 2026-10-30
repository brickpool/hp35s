use strict;
use warnings;

use Test::More;

use lib 't/lib';
use FrontendTest qw( run_frontend );

subtest 'macro definitions are accepted in the program header' => sub {
  my $source = <<'ASM';
; leading comment
; another comment
MACRO PUSH value
  value
  STO(I)
  DSE I
ENDM

IDEAL
P35S
MODEL TINY

CODESEG
  1
  STO I
  PUSH 9.1
  RTN
END
ASM

  my ($status, $output, $errors) = run_frontend($source);

  is( $status, 0, 'frontend succeeds' );
  is( $errors, '', 'no parser warnings' );

  like(
    $output,
    qr/\b9\.1\b/,
    'macro body is expanded after leading comments',
  );
};

done_testing;
