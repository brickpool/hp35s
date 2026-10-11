use strict;
use warnings;

use File::Find;
use File::Spec;
use Test::More;
use lib 't/lib';
use FrontendTest qw( run_frontend );

my @sources;
find(
  {
    no_chdir => 1,
    wanted => sub { push @sources, $File::Find::name if /\.asm\z/i },
  },
  'examples',
);
@sources = sort @sources;
plan skip_all => 'No assembler examples found' unless @sources;

for my $source_file ( @sources ) {
  my $reference_file = $source_file;
  $reference_file =~ s/\.asm\z/.35s/i;
  my $relative_source = File::Spec->canonpath($source_file);

  subtest $relative_source => sub {
    if ( $relative_source eq File::Spec->canonpath(
      'examples/3rd-party/Mancala/mancala.asm'
    ) ) {
      plan skip_all => 'Original HP-41S listing; M.asm is the HP-35s example';
    }

    ok( -f $reference_file, 'matching .35s reference exists' ) or return;

    open my $source_handle, '<', $source_file
      or die "Cannot open $source_file: $!";
    my $source = do { local $/; <$source_handle> };
    close $source_handle or die "Cannot close $source_file: $!";

    open my $reference_handle, '<', $reference_file
      or die "Cannot open $reference_file: $!";
    my $expected = do { local $/; <$reference_handle> };
    close $reference_handle or die "Cannot close $reference_file: $!";

    my ($status, $actual, $errors) = run_frontend(
      $source, '-j', '-s', '-u', '-f', $source_file
    );
    diag("assembler stderr: $errors") if length $errors;
    is( $status, 0, 'assembler succeeds' );
    my $matches = $actual eq $expected;
    ok( $matches, 'output matches .35s reference' );
    unless ( $matches ) {
      my @actual_lines = split /\n/, $actual, -1;
      my @expected_lines = split /\n/, $expected, -1;
      my $last_line = @actual_lines > @expected_lines
        ? $#actual_lines : $#expected_lines;
      for my $index ( 0 .. $last_line ) {
        next if defined $actual_lines[$index]
          && defined $expected_lines[$index]
          && $actual_lines[$index] eq $expected_lines[$index];
        diag('first difference at line ' . ($index + 1)
          . "\n  expected: " . ($expected_lines[$index] // '<EOF>')
          . "\n  actual:   " . ($actual_lines[$index] // '<EOF>'));
        last;
      }
    }
  };
}

done_testing;