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
        return $self->parse_label;
      },
    );
  }

  $INC{'ParserTest.pm'} = 1;
}

use_ok 'ParserTest';

subtest 'label declaration is parsed and registered' => sub {
  my $parser = ParserTest->new();

  is_deeply(
    $parser->from_string("START:\n"),
    { 
      label => { 
        type => 'label',
        name => 'START',
      } 
    },
    'global label',
  );
  is( $parser->{symbols}->{START}, 'label', 'label is registered' );
};

subtest 'label names are case-insensitive' => sub {
  for my $source ( qw(START: Start: start:) ) {
    my $parser = ParserTest->new();

    is_deeply(
      $parser->from_string("$source\n"),
      { 
        label => { 
          type => 'label',
          name => 'START',
        } 
      },
      "$source is normalized",
    );
    is( 
      $parser->{symbols}->{START}, 
      'label', 
      'canonical symbol is registered'
    );
  }
};

subtest 'label accepts supported label names' => sub {
  my @valid = (
    [ 'start:',   'START',   'label' ],
    [ '@shared:', '@SHARED', 'label' ],
    [ '@@local:', '@@LOCAL', 'local' ],
    [ '$2:',      '$2',      'label' ],
    [ 'A00:',     'A00',     'label' ],
  );

  for my $case (@valid) {
    my ($source, $name, $type) = @$case;
    my $parser = ParserTest->new();

    is_deeply(
      $parser->from_string("$source\n"),
      {
        label => {
          type => $type,
          name => $name,
        },
      },
      "$source is accepted",
    );

    if ($type eq 'label') {
      is(
        $parser->{symbols}{$name},
        'label',
        "$name is registered",
      );
    }
    else {
      ok(
        !exists $parser->{symbols}{$name},
        "$name is unresolved",
      );
    }
  }
};

subtest 'invalid labels' => sub {
  my @invalid = (
    [ '123:',     "Labels can't start with numeric characters" ],
    [ '12ab:',    "Labels can't start with numeric characters" ],
    [ '1ABC:',    "Labels can't start with numeric characters" ],
    [ 'A123:',    "Illegal segment address" ],
    [ '??0000:',  "Illegal segment address" ],
    [ '@@0000:',  "Illegal segment address" ],
    [ 'START :',  "Illegal segment address" ],
  );

  for my $case (@invalid) {
    my ($source, $error) = @$case;
    my $parser = ParserTest->new();

    throws_ok { $parser->from_string($source) } qr/\Q$error\E/, 
      "$source is rejected";
  }
};

subtest 'duplicate labels are case-insensitive' => sub {
  my $source = "start:\n";
  my $parser = ParserTest->new();
  $parser->{symbols}->{START} = 'label';

  throws_ok {
    $parser->from_string($source);
  } qr/Symbol already defined/,
    'different spelling is the same label';

  is( $@->{pos}, 0, 'failure position' );
};

subtest 'label rejects a symbol of another kind' => sub {
  my $source = "value:\n";
  my $parser = ParserTest->new();
  $parser->{symbols}->{VALUE} = 'equation';

  throws_ok {
    $parser->from_string($source);
  } qr/Symbol already different kind/,
    'existing symbol of another kind is rejected';

  is( $@->{pos}, 0, 'failure position' );
};

subtest 'label requires a colon' => sub {
  my $source = "START\n";
  my $parser = ParserTest->new();

  throws_ok {
    $parser->from_string($source);
  } qr/Illegal segment address/,
    'missing colon is rejected';

  is( $@->{pos}, 0, 'failure position' );
};

done_testing;
