use strict;
use warnings;

use Test::More;
use Parser::HPC;

sub parse_program_with_title {
  my ($title) = @_;
  return Parser::HPC->new->from_string(<<ASM);
$title
IDEAL
P35S
MODEL TINY
CODESEG
  RTN
END
ASM
}

sub parse_program_error {
  my ($title) = @_;
  my $success = eval { parse_program_with_title($title); 1 };
  my $error = "$@";
  note $error if $ENV{AUTHOR_TESTING} && !$success;
  return $error;
}

subtest '%TITLE accepts valid delimiters' => sub {
  for my $title (
    '%TITLE "I/O Library"',
    qq{%TITLE\t"I/O Library"},
  ) {
    my $program = parse_program_with_title($title);
    is( $program->{title}, 'I/O Library', "$title is parsed" );
  }
};

subtest '%TITLE rejects invalid delimiters' => sub {
  for my $title (
    '%TITLE"I/O Library"',
    '%TITLE. "I/O Library"',
    '%TITLE: "I/O Library"',
    '%TITLEX "I/O Library"',
    '%TITLE_ "I/O Library"',
  ) {
    my $error = parse_program_error($title);
    like( $error, qr/IDEAL must be specified first/,
      "$title is not recognized as a title directive" );
  }
};

subtest '%TITLE may only be used once' => sub {
  my $error = parse_program_error(
    "%TITLE \"First\"\n%TITLE \"Second\""
  );
  like( $error, qr/IDEAL must be specified first/,
    'the second %TITLE is rejected where IDEAL is required' );
};

subtest '%TITLE reports string errors' => sub {
  my @cases = (
    [ '%TITLE ', qr/Need quoted string on line 1/, 'missing quoted string' ],
    [ 
      qq{%TITLE "I/O\nLibrary"},
      qr/Missing end quote on line 1 at:\n%TITLE "I\/O\n {11}\^\n/,
      'newline in title after I/O'
    ],
    [ '%TITLE "I/O Library" extra', 
      qr/Extra characters on line 1/, 
      'extra characters after title'
    ],
  );
  for my $case (@cases) {
    my ($title, $message, $description) = @$case;
    my $error = parse_program_error($title);
    like( $error, $message, "$description reports the expected error" );
  }
};

subtest '%TITLE allow uppercase spelling' => sub {
  for my $title (
    '%title "I/O Library"',
    '%Title "I/O Library"',
    '%TiTlE "I/O Library"',
  ) {
    my $program = parse_program_with_title($title);
    is( $program->{title}, 'I/O Library', "$title is parsed" );
  }
};

done_testing;
