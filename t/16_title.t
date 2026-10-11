use strict;
use warnings;

use Test::More;
use Parser::HPC;

sub parse_program_with_title {
  my ($title) = @_;
  return Parser::HPC->new->from_string(<<ASM);
$title
MODEL P35S
SEGMENT CODE
RTN
ENDS
END
ASM
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

subtest '%TITLE cannot share a line with MODEL' => sub {
  my $success = eval {
    parse_program_with_title('%TITLE "I/O Library" MODEL P35S');
    1;
  };
  my $error = "$@";
  ok( !$success, '%TITLE followed by MODEL on the same line is rejected' );
  like( $error, qr/Extra characters on line/, 'line-ending error is reported' );
};

subtest '%TITLE rejects invalid delimiters' => sub {
  for my $title (
    '%TITLE"I/O Library"',
    '%TITLE. "I/O Library"',
    '%TITLE: "I/O Library"',
    '%TITLEX "I/O Library"',
    '%TITLE_ "I/O Library"',
  ) {
    my $success = eval { parse_program_with_title($title); 1 };
    ok( !$success, "$title is rejected" );
  }
};

subtest '%TITLE may only be used once' => sub {
  my $success = eval {
    parse_program_with_title(
      "%TITLE \"First\"\n%TITLE \"Second\""
    );
    1;
  };
  ok( !$success, 'a second %TITLE is rejected' );
};

subtest '%TITLE reports string errors' => sub {
  my @cases = (
    [ '%TITLE ', qr/Need quoted string/, 'missing quoted string' ],
    [ qq{%TITLE "I/O\nLibrary"}, qr/Missing end quote/, 'newline in title' ],
  );
  for my $case (@cases) {
    my ($title, $message, $description) = @$case;
    my $success = eval { parse_program_with_title($title); 1 };
    my $error = "$@";
    ok( !$success, "$description is rejected" );
    like( $error, $message, "$description reports the expected error" );
  }
};

subtest '%TITLE requires uppercase spelling' => sub {
  for my $title (
    '%title "I/O Library"',
    '%Title "I/O Library"',
    '%TiTlE "I/O Library"',
  ) {
    my $success = eval { parse_program_with_title($title); 1 };
    ok( !$success, "$title is rejected" );
  }
};

done_testing;
