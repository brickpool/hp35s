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
    { label => { name => 'START' } },
    'global label',
  );
  is( $parser->{symbols}->{START}, 'label', 'label is registered' );
};

subtest 'label names are case-insensitive' => sub {
  for my $source ( qw(START: Start: start:) ) {
    my $parser = ParserTest->new();

    is_deeply(
      $parser->from_string("$source\n"),
      { label => { name => 'START' } },
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
  for my $case (
    [ 'start:',    'START'    ],
    [ '@shared:',  '@SHARED'  ],
    [ '@@local:',  ':@@LOCAL' ],
    [ '??0000:',   '??0000'   ],
  ) {
    my ($source, $name) = @$case;
    my $parser = ParserTest->new();

    is_deeply(
      $parser->from_string("$source\n"),
      { label => { name => $name } },
      "$source is accepted",
    );

    is( $parser->{symbols}->{$name}, 'label', "$name is registered" );
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
  } qr/Expected.*:/,
    'missing colon is rejected';
};

done_testing;
