use strict;
use warnings;

use Test::More;
use Parser::HPC;

subtest 'macro errors reject invalid source and preserve known diagnostics' => sub {
  my @cases = (
    [ "MACRO \nENDM\n", "Missing macro ID on line 2 at:\nENDM\n    ^\n" ],
    [ "MACRO TESTMACRO a,a\nENDM\n",
      "Duplicate dummy argument: a on line 1 at:\nMACRO TESTMACRO a,a\n" . (' ' x 19) . "^\n" ],
    [ "MACRO TESTMACRO 123\nENDM\n",
      "Illegal macro argument on line 1 at:\nMACRO TESTMACRO 123\n" . (' ' x 16) . "^\n" ],
    [ "MACRO TESTMACRO\nLOCAL 123\nENDM\n", "Illegal local argument\n" ],
    [ "MACRO OUTER\nMACRO INNER\nENDM\nENDM\n", undef ],
    [ "ENDM\n", "Can't use this outside macro\n" ],
    [ "MACRO TESTMACRO\nENDM\nIDEAL\nP35S\nMODEL TINY\nSEGMENT CODE\nXEQ TESTMACRO\nENDS\nEND\n",
      "Can't use macro name in expression: TESTMACRO\n" ],
    [ "MACRO TESTMACRO\nENDM\nIDEAL\nP35S\nMODEL TINY\nSEGMENT CODE\nXEQ testmacro\nENDS\nEND\n",
      "Can't use macro name in expression: testmacro\n" ],
  );
  for my $case (@cases) {
    my ($source, $expected_error) = @$case;
    my $success = eval { Parser::HPC->new->from_string($source); 1 };
    my $error = "$@";
    ok( !$success, 'invalid macro source is rejected' );
    if (defined $expected_error) {
      if ($source =~ /\nLOCAL\b/) {
        like( $error, qr/\AIllegal local argument on line 2 at:/,
          'LOCAL diagnostic includes its source position' );
      }
      else {
        is( $error, $expected_error, 'exact diagnostic is reported' );
      }
    }
  }
};

subtest 'MASM macro syntax is rejected' => sub {
  my $source = <<'ASM';
IDEAL
P35S
MODEL TINY
SEGMENT CODE
M MACRO
  RTN
ENDM
ENDS
END
ASM
  my $success = eval { Parser::HPC->new->from_string($source); 1 };
  ok( !$success, 'MASM-style definition is not accepted' );
};

subtest 'EXITM is not a supported directive' => sub {
  my $source = <<'ASM';
IDEAL
P35S
MODEL TINY
SEGMENT CODE
EXITM
ENDS
END
ASM
  my $success = eval { Parser::HPC->new->from_string($source); 1 };
  my $error = "$@";
  ok( !$success, 'EXITM is rejected as a code statement' );
  like( $error, qr/Illegal instruction/,
    'EXITM does not use the macro-only directive diagnostic' );
};

subtest 'macro grammar rejects incomplete scopes and identifier lists' => sub {
  my @cases = (
    [ "MACRO TESTMACRO\n  RTN\n", undef ],
    [ "MACRO TESTMACRO arg,", undef ],
    [ "MACRO TESTMACRO\nLOCAL arg,", undef ],
    [ "MACRO TESTMACRO arg\nENDM\nTESTMACRO\n",
      "Illegal macro argument on line 3 at:\nTESTMACRO\n         ^\n" ],
    [ "MACRO TESTMACRO\nENDM extra\n", "Extra characters on line 2 at:\nENDM extra\n     ^\n" ],
  );
  for my $case (@cases) {
    my ($source, $expected_error) = @$case;
    my $success = eval { Parser::HPC->new->from_string($source); 1 };
    my $error = "$@";
    ok( !$success, 'invalid macro grammar is rejected' );
    if (defined $expected_error) {
      if ($source =~ /\nLOCAL\b/) {
        like( $error, qr/\AIllegal local argument on line 2 at:/,
          'LOCAL diagnostic includes its source position' );
      }
      else {
        is( $error, $expected_error, 'the grammar reports the expected diagnostic' );
      }
    }
  }
};

subtest 'LOCAL reports only the two supported diagnostics' => sub {
  my @cases = (
    [ '', 'Illegal local argument' ],
    [ '; comment', 'Illegal local argument' ],
    [ '123', 'Illegal local argument' ],
    [ 'name:WORD', 'Extra characters' ],
    [ 'name,123', 'Illegal local argument' ],
    [ 'name,,other', 'Illegal local argument' ],
    [ 'name other', 'Extra characters' ],
    [ 'name :WORD', 'Extra characters' ],
    [ 'name + 1', 'Extra characters' ],
  );
  for my $case (@cases) {
    my ($arguments, $diagnostic) = @$case;
    my $source = "MACRO TESTMACRO dummy\n  LOCAL $arguments\nENDM\n";
    my $success = eval { Parser::HPC->new->from_string($source); 1 };
    my $error = "$@";
    ok( !$success, "LOCAL $arguments is rejected" );
    like( $error, qr/\A\Q$diagnostic\E on line 2 at:\n  LOCAL /,
      'the supported diagnostic includes the LOCAL source line' );
    like( $error, qr/\n *\^\n\z/, 'a caret marks the source position' );
  }
};

subtest 'Reserved symbols are rejected as macro and LOCAL names' => sub {
  my $new_parser = sub {
    return Parser::HPC::Macro->new(
      patterns => { ident => Parser::HPC::pattern_ident() },
    );
  };
  for my $case ([ 'RTN', 1 ], [ 'pi', 1 ], [ 'Vm', 1 ],
    [ 'rtn', 1 ], [ 'PI', 1 ], [ 'VM', 1 ]) {
    my ($name, $reserved) = @$case;
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    my $parser = $new_parser->();
    my $success = eval { $parser->from_string("MACRO $name\nENDM\n"); 1 };
    if ($reserved) {
      ok( !$success, "$name is rejected as a macro name" );
      like( "$@", qr/\ASymbol already different kind on line 1 at:\nMACRO \Q$name\E\n\s+\^\n\z/,
        'reserved macro diagnostic includes its source position' );
    }
    else {
      ok( $success, "$name is accepted as a macro name" );
    }
    is( scalar @warnings, 0, 'macro name check does not emit a warning' );
    $parser = $new_parser->();
    my $local_success = eval {
      $parser->from_string("MACRO TESTMACRO\nLOCAL name,$name\nENDM\n"); 1
    };
    if ($reserved) {
      ok( !$local_success, "$name is rejected in a LOCAL list" );
      like( "$@", qr/\ASymbol already different kind on line 2 at:\nLOCAL name,\Q$name\E\n\s+\^\n\z/,
        'reserved LOCAL diagnostic includes its source position' );
    }
    else {
      ok( $local_success, "$name is accepted in a LOCAL list" );
    }
    is( scalar @warnings, 0, 'LOCAL name check does not emit a warning' );
  }
};

done_testing;