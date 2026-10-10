use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'Parser::MGC';
}

BEGIN {
  package Test::Parser;
  use strict;
  use warnings;

  use parent 'Parser::MGC';

  sub radix {
    my ( $self, $radix ) = @_;
    $self->{_radix} = $radix if defined $radix;
    return $self->{_radix};
  }

  sub parse {
    my $self = shift;
    $self->{_radix} //= 10;
    return $self->token_number;
  }

  sub token_number {
    my $self = shift;
    my $value = $self->any_of(
      'token_binary',
      'token_octal',
      'token_decimal',
      'token_hex',
      sub {
        SWITCH: for ( $self->{_radix} || 10 ) {
          /2/ and return $self->generic_token( 
            decimal => qr/[01]+\b/,
            sub {
              no warnings 'portable';
              my $value = oct( '0b'. $_[1] );
              $value -= 2**36 if $value >= 2**35;
              return $value;
            }
          );
          /8/ and return $self->generic_token( 
            octal => qr/[0-7]+\b/,
            sub {
              no warnings 'portable';
              my $value = oct( '0'. $_[1] );
              $value -= 2**36 if $value >= 2**35;
              return $value;
            }
          );
          /16/ and return $self->generic_token(
            hex => qr/[\dA-F]+\b/,
            sub {
              no warnings 'portable';
              my $value = hex( $_[1] );
              $value -= 2**36 if $value >= 2**35;
              return $value;
            }
          );
        }
        return $self->SUPER::token_number;
      }
    );
    return $value;
  }

  sub token_binary {
    return shift->generic_token( binary => qr/[01]+b\b/ );
  }
  
  sub token_octal {
    return shift->generic_token( octal => qr/[0-7]+o\b/ );
  }

  sub token_decimal {
    return shift->generic_token( decimal => qr/-?\d+d\b/ );
  }

  sub token_hex {
    return shift->generic_token( hex => qr/[\dA-F]+h\b/ );
  }

  $INC{'Test/Parser.pm'} = 1;
}

use_ok 'Test::Parser';

my $parser = Test::Parser->new();

subtest 'decimal radix' => sub {
  $parser->radix(10);

  is( $parser->from_string('1'), 1, 'integer 1' );
  is( $parser->from_string('125'), 125, 'integer 125' );
  is( $parser->from_string('-125'), -125, 'negative integer' );
  is( $parser->from_string('1.25'), 1.25, 'float' );
};

subtest 'binary radix' => sub {
  $parser->radix(2);

  is( $parser->from_string('1'), 1, 'binary 1' );
  is( $parser->from_string('1001'), 9, 'binary 1001' );

  is(
    $parser->from_string('111111111111111111111111111111111111'),
    -1,
    '36-bit binary -1'
  );
};

subtest 'octal radix' => sub {
  $parser->radix(8);

  is( $parser->from_string('7'), 7, 'octal 7' );
  is( $parser->from_string('10'), 8, 'octal 10' );

  is(
    $parser->from_string('777777777777'),
    -1,
    '36-bit octal -1'
  );
};

subtest 'hexadecimal radix' => sub {
  $parser->radix(16);

  is( $parser->from_string('1'), 1, 'hex 1' );
  is( $parser->from_string('7D'), 125, 'hex 7D' );
  is( $parser->from_string('FFFFFFFFF'), -1, '36-bit hex -1' );
  is( $parser->from_string('FFFFFFF83'), -125, '36-bit hex -125' );
};

subtest 'explicit suffix' => sub {
  $parser->radix(10);

  is( $parser->from_string('1b'), '1b', 'binary suffix' );
  is( $parser->from_string('7o'), '7o', 'octal suffix' );
  is( $parser->from_string('125d'), '125d', 'decimal suffix' );
  is( $parser->from_string('7Dh'), '7Dh', 'hex suffix' );
};

subtest 'invalid input' => sub {
  dies_ok { $parser->from_string('0k') } 'invalid token 0k';
};

done_testing();
