use strict;
use warnings;

use Test::More;

use lib 't/lib';
use FrontendTest qw( run_frontend );

subtest 'local labels produce same output as explicit scoped labels' => sub {
  my $source = <<'ASM';
MODEL TINY
CODESEG
start:
  LBL A
  GTO @@loop
@@loop:
  RPN
  XEQ @@LOOP
next:
  GTO @@loop
@@loop:
  RTN
  GTO @@loop
END start
ASM

  my ($first_scope, $next_scope) = split m{(?=^next:)}m, $source;
  $first_scope =~ s/\@\@loop/first_loop/ig;
  $next_scope =~ s/\@\@loop/second_loop/ig;
  my $explicit = $first_scope . $next_scope;

  for my $options ( [], [ '-j' ], [ '-s' ] ) {
    my ($status, $output, $errors) = run_frontend($source, @$options);
    my ($expected_status, $expected, $expected_errors) =
      run_frontend($explicit, @$options);

    is( $status, 0, 'local source assembles' );
    is( $errors, '', 'local source has no warnings' );
    is( $expected_status, 0, 'explicit source assembles' );
    is( $expected_errors, '', 'explicit source has no warnings' );
    is( $output, $expected,
      'local and explicit scoped labels produce identical output' );
  }
};

done_testing;
