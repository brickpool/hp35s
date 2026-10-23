use strict;
use warnings;

use Test::More;
use Test::Exception;
use Parser::HPC;

{
  package ParserTest;
  use parent 'Parser::HPC';
  sub parse {
    return shift->any_of('parse_model');
  }
  $INC{'ParserTest.pm'} = 1;
}

use_ok 'ParserTest';

subtest 'MODEL accepts supported model types' => sub {
  my @models = (
    [ TINY    => 0 ],
    [ SMALL   => 1 ],
    [ COMPACT => 2 ],
    [ MEDIUM  => 3 ],
    [ LARGE   => 4 ],
    [ HUGE    => 5 ],
  );

  for my $case (@models) {
    my ($model, $value) = @$case;
    my $parser = ParserTest->new();

    is_deeply(
      $parser->from_string("MODEL $model\n"),
      { model => $value },
      "MODEL $model",
    );

    is( $parser->{model}, $value, "model is set to $value" );
  }
};

subtest 'MODEL accepts horizontal whitespace' => sub {
  for my $source (
    "MODEL TINY\n",
    "MODEL\tTINY\n",
  ) {
    my $parser = ParserTest->new();

    is_deeply(
      $parser->from_string($source),
      { model => 0 },
      $source =~ /\t/ ? 'tab delimiter' : 'space delimiter',
    );
  }
};

subtest 'MODEL is case-insensitive' => sub {
  for my $source (
    "model tiny\n",
    "Model Tiny\n",
    "MoDeL TiNy\n",
  ) {
    my $parser = ParserTest->new();

    is_deeply(
      $parser->from_string($source),
      { model => 0 },
      "$source is accepted",
    );
  }
};

subtest 'MODEL requires a valid model type' => sub {
  for my $model (
    'UNKNOWN',
    'MICRO',
    'TINYextra',
  ) {
    my $source = "MODEL $model\n";
    my $parser = ParserTest->new();

    throws_ok {
      $parser->from_string($source);
    } qr/Invalid model type/,
      "MODEL $model is rejected";

    is( $@->{pos}, length('MODEL'), 'failure position' );
  }
};

subtest 'MODEL requires a model type' => sub {
  my $source = "MODEL \n; comment";
  my $parser = ParserTest->new();

  throws_ok {
    $parser->from_string($source);
  } qr/Invalid model type/,
    'missing model type';

  is( $@->{pos}, length('MODEL'), 'failure position' );
};

subtest 'MODEL requires the model type on the same line' => sub {
  my $source = "MODEL \nTINY\n";
  my $parser = ParserTest->new();

  throws_ok {
    $parser->from_string($source);
  } qr/Invalid model type/,
    'model type on the next line';

  is(
    $@->{pos},
    index($source, 'TINY') + length('TINY'),
    'failure position',
  );
};

subtest 'MODEL rejects trailing characters' => sub {
  my $source = "MODEL TINY extra\n";
  my $parser = ParserTest->new();

  throws_ok {
    $parser->from_string($source);
  } qr/Extra characters/,
    'trailing characters';

  is( $@->{pos}, index( $source, 'extra' ), 'failure position', );
};

done_testing;
