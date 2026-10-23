use strict;
use warnings;

use Test::More;
use Test::Exception;
use Parser::HPC;

{
  package ParserTest;
  use parent 'Parser::HPC';
  sub parse {
    my $self = shift;
    return $self->any_of(
      sub {
        $self->commit;
        return $self->parse_code_literal;
      },
    );
  }
  $INC{'ParserTest.pm'} = 1;
}

use_ok 'ParserTest';

subtest 'code literal parses explicit numeric types' => sub {
  for my $case (
    [ '101b', 'binary',  '101b' ],
    [ '12o',  'octal',   '12o'  ],
    [ '12d',  'decimal', '12d'  ],
    [ '17h',  'hex',     '17h'  ],
    [ '2.5',  'decimal', '2.5'  ],
    [ '7e-1', 'decimal', '0.7'  ],
  ) {
    my ($source, $kind, $value) = @$case;
    my $parser = ParserTest->new();

    is_deeply(
      $parser->from_string("$source\n"),
      { literal => { kind => $kind, value => $value } },
      "$source is parsed as $kind",
    );
  }
};

subtest 'code literal parses vectors and complex values' => sub {
  for my $case (
    [ '[1,2]',   'vector'  ],
    [ '[1,2,3]', 'vector'  ],
    [ '1i2',     'complex' ],
  ) {
    my ($source, $kind) = @$case;
    my $parser = ParserTest->new();

    is_deeply(
      $parser->from_string("$source\n"),
      { literal => { kind => $kind, value => $source } },
      "$source is parsed as $kind",
    );
  }
};

subtest 'code literal applies the active radix to unsuffixed integers' => sub {
  for my $case (
    [ 2,  '100', 'binary',  '100b' ],
    [ 8,  '100', 'octal',   '100o' ],
    [ 10, '100', 'decimal', '100'  ],
    [ 16, '100', 'hex',     '100h' ],
  ) {
    my ($radix, $source, $kind, $value) = @$case;
    my $parser = ParserTest->new();
    $parser->{radix} = $radix;

    is_deeply(
      $parser->from_string("$source\n"),
      { literal => { kind => $kind, value => $value } },
      "RADIX $radix parses $source as $kind",
    );
  }
};

subtest 'code literal rejects trailing characters' => sub {
  my $source = "12d extra\n";
  my $parser = ParserTest->new();

  throws_ok {
    $parser->from_string($source);
  } qr/Extra characters/,
    'trailing characters are rejected';

  is( $@->{pos}, index($source, 'extra'), 'failure position' );
};

subtest 'code literal rejects an invalid value' => sub {
  my $source = "not_a_literal\n";
  my $parser = ParserTest->new();

  throws_ok {
    $parser->from_string($source);
  } qr/./,
    'invalid literal is rejected';

  is( $@->{pos}, 0, 'failure position' );
};

subtest 'code literal parses constants' => sub {
  for my $constant ( qw(pi i e) ) {
    my $parser = ParserTest->new();

    is_deeply(
      $parser->from_string("$constant\n"),
      { literal => { kind => 'constant', value => $constant } },
      "$constant is parsed as a constant",
    );
  }
};

done_testing;
