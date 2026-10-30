use strict;
use warnings;

use Test::More;
use Test::Exception;

{
  package ParserTest;
  use parent 'Parser::MGC';

  sub parse {
    my $self = shift;

    return $self->include_string(
      "INVALID\n",
      toplevel => 'parse_included',
    );
  }

  sub parse_included {
    my $self = shift;

    $self->expect(qr/VALID\b/);
    return 1;
  }

  my $include_string = Parser::MGC->can('include_string');
  $include_string //= sub {
    my $self = shift;
    my ( $str, %opts ) = @_;

    # local'ize everything out of the way
    local @{$self}{qw( str filename reader )};
    $self->{str} = $str;

    pos($self->{str}) = 0;
    $self->{filename} = $opts{filename};

    my $toplevel = $opts{toplevel} // $self->{toplevel};
    my $result = $self->$toplevel;

    return $result;
  };

  sub include_string {
    my $self = shift;

    local $@;
    local ($self->{str}) = @_;

    my $result = eval {
      $self->$include_string(@_);
    };

    if ($@) {
      my $error = $@;
      die ref($error) eq 'Parser::MGC::Failure'
        ? $error->STRING
        : $error;
    }

    return $result;
  }

  $INC{'ParserTest.pm'} = 1;
}

use_ok 'ParserTest';

subtest 'include_string failure keeps included source context' => sub {
  my $parser = ParserTest->new();

  throws_ok {
    $parser->from_string('');
  } qr/Expected .*VALID.* on line 1.*INVALID/s,
    'failure from included string is reported against included source';
};

done_testing;
