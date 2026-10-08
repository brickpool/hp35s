package FrontendTest;

use strict;
use warnings;

use Exporter 'import';
use File::Temp qw( tempfile );
use IPC::Open3;

our @EXPORT_OK = qw( run_frontend );

sub run_frontend {
  my $source = shift;
  my @options = @_;
  my ($input) = tempfile( UNLINK => 1 );
  my ($output) = tempfile( UNLINK => 1 );
  my ($errors) = tempfile( UNLINK => 1 );
  binmode $output, ':crlf' or die "Cannot set output text mode: $!";
  binmode $errors, ':crlf' or die "Cannot set errors text mode: $!";
  print {$input} $source;
  seek $input, 0, 0 or die "Cannot rewind input: $!";

  my $process = open3(
    '<&' . fileno($input),
    '>&' . fileno($output),
    '>&' . fileno($errors),
    $^X, '-Ilib', 'bin/asm2hpc.pl', @options,
  );
  waitpid $process, 0;
  my $status = $?;
  seek $output, 0, 0 or die "Cannot rewind output: $!";
  seek $errors, 0, 0 or die "Cannot rewind errors: $!";
  local $/;
  return ($status, scalar <$output>, scalar <$errors>);
}

1;