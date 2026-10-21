use strict;
use warnings;

use Cwd qw( getcwd );
use File::Path qw( make_path );
use File::Spec;
use File::Temp qw( tempfile tempdir );
use IPC::Open3;
use Parser::HPC;
use Test::More;

my $directory = tempdir( CLEANUP => 1 );
my $repository = getcwd();
my $source_directory = File::Spec->catdir($directory, 'examples', 'C');
make_path($source_directory);
my $source_file = File::Spec->catfile($source_directory, 'listing.asm');
my $listing_file = File::Spec->catfile($directory, 'listing.lst');
my $script = File::Spec->catfile($repository, 'bin', 'asm2hpc.pl');
my $source = <<'ASM';
; heading
%TITLE "Listing"
IDEAL
P35S
MODEL TINY

CODESEG
; comment
  LBL A
  RTN
; repeated opcode
  RTN
END
ASM

open my $source_handle, '>', $source_file
  or die "Can't create $source_file: $!";
print {$source_handle} $source;
close $source_handle or die "Can't write $source_file: $!";

my ($input) = tempfile( UNLINK => 1 );
my ($output) = tempfile( UNLINK => 1 );
my ($errors) = tempfile( UNLINK => 1 );
binmode $output, ':crlf' or die "Cannot set output text mode: $!";
binmode $errors, ':crlf' or die "Cannot set errors text mode: $!";
chdir $directory or die "Can't change directory to $directory: $!";
my $process = open3(
  '<&' . fileno($input),
  '>&' . fileno($output),
  '>&' . fileno($errors),
  $^X, "-I" . File::Spec->catdir($repository, 'lib'), $script,
  '-l', '-f', $source_file,
);
waitpid $process, 0;
my $status = $?;
chdir $repository or die "Can't change directory to $repository: $!";
seek $output, 0, 0 or die "Cannot rewind output: $!";
seek $errors, 0, 0 or die "Cannot rewind errors: $!";
local $/;
my $stdout = <$output>;
my $stderr = <$errors>;

is( $status, 0, 'assembler succeeds with -l and -f' );
is( $stderr, '', 'assembler reports no errors' );
is( $stdout, '', 'listing mode suppresses normal stdout output' );
ok( -e $listing_file, 'listing is written in the current directory' );

if (-e $listing_file) {
  open my $listing_handle, '<', $listing_file
    or die "Can't read $listing_file: $!";
  binmode $listing_handle, ':crlf'
    or die "Cannot set listing text mode: $!";
  my $listing = <$listing_handle>;
  my @listing_lines = split /\n/, $listing;
  my @source_lines = split /\n/, $source;
  is( scalar @listing_lines, scalar @source_lines,
    'listing contains every physical source line' );

  for my $index (0 .. $#source_lines) {
    my ($depth, $line_number, $offset, $code, $source_text) =
      $listing_lines[$index] =~ /\A(.) (.{4}) (.{4}) (.{20}) (.*)\z/;
    ok( defined $source_text, 'listing fields have their configured widths' );
    next unless defined $source_text;
    is( $depth, ' ', 'depth is blank for normal source lines' );
    is( $line_number, sprintf('%4d', $index + 1), 'line number is right-aligned' );
    is( $source_text, $source_lines[$index], 'source text is preserved' );
    if ($index == 8 || $index == 9 || $index == 11) {
      is( $offset, '0000', 'emitted statement has the dummy offset' );
      is( substr($code, -8), '?? ?? ??', 'emitted statement has three dummy bytes' );
    }
    else {
      is( $offset, '    ', 'non-code line has a blank offset' );
      is( $code, ' ' x 20, 'non-code line has a blank code field' );
    }
  }
}

subtest 'parser attaches physical source IDs to data and code nodes' => sub {
  my $program_source = <<'ASM';
IDEAL
P35S
MODEL TINY
DATASEG
VALUE EQU 'A'
CODESEG
start: LBL A
  RTN
END
ASM
  my $parser = Parser::HPC->new;
  $parser->{_track_source_ids} = 1;
  my $program = $parser->from_string($program_source);
  my ($data) = grep { $_->{type} eq 'data' } @{ $program->{segments} };
  my ($code) = grep { $_->{type} eq 'code' } @{ $program->{segments} };

  is( $data->{definitions}->[0]->{_source_id}, 5,
    'data node refers to its original source line' );
  is( $code->{statements}->[0]->{_source_id}, 7,
    'label node refers to its original source line' );
  is( $code->{statements}->[1]->{_source_id}, 7,
    'label and instruction on one line share their source ID' );
  is( $code->{statements}->[2]->{_source_id}, 8,
    'following instruction retains its own source ID' );
};

done_testing;
