#!/usr/bin/perl
#
# (c) 2019 brickpool
#     J.Schneider (http://github.com/brickpool/)
#
# simple recursive-descent one-pass assembler parser for HP calculators
#
#######################################################################
#
# Changelog: 
#   http://github.com/brickpool/hp35s/CHANGELOG.md
#
# ToDo:
#   - the directive %TITLE, DISPLAY and RADIX
#     and the symbols TIME and DATE are not implemented
#   - only the polish notation mode is supported

use strict;
use warnings;

=head1 NAME

C<HpcParser> - simple recursive-descent one-pass assembler parser for HP calculators

=cut

package Parser::HPC;
use strict;
use warnings;

use Exporter;
our @EXPORT = qw(@instructions @with_address @with_digits @with_variables @with_indirects @expressions @functions @register);
require Parser::MGC;
our @ISA = qw(Exporter Parser::MGC);

=head1 PATTERNS
The following pattern names are recognised.

=over 4

=item * comment

Pattern used to skip comments between tokens. Defaults to C</;.*\n+/>

=back

=cut

use constant pattern_comment    => qr/;.*\n/;
use constant pattern_operation  => qr/[^\s\(\)]+/;
use constant unknown_equ_chars  => qr/[#\$&:;\?\@_`\{\}]/;

my @directives = (
  'DISPLAY', 'ENDS', 'END', 'EQU', 'MODEL', 'RADIX', 'SEGMENT', 'SET', '%TITLE',
);

my @predefined = (
  'DATE', 'TIME',
);

my @languages = (
  'P35S',
);

my @segments = (
  'DATA', 'CODE', 'STACK',
);

our @instructions = (
  # G1
  '+/-', '+', '-', '*', '/',
  # G2
  '1/x', '10^x', '%', '%CHG', 'pi', 'Z+', 'Z-',
  # G3
  'Zx', 'Zx^2', 'Zxy', 'Zy', 'Zy^2', 'zx', 'zy',
  # G4
  'ALG', 'ALL', 'AND',
  # G5
  'b', 'BIN', '/c',
  # G6
  'CLZ', 'CLx', 'CLVARS', 'CLSTK', 'nCr', 'DEC', 'DEG', 
  # G7
  '<-ENG', 'ENG->', 'ENTER', 'e^x',
  # G8
  'FP', 'GRAD', 'HEX',
  # G9
  '->HMS', 'HMS->', '->IN', 'INT/', 'INTG', 
  # G10
  'IP', '->KG', '->KM', '->L', 'LASTx', '->LB', 'LN', 'LOG', 'm', 
  # G11
  '->MILE', 'n', 'NAND', 'NOR', 'NOT', 'OCT', 'OR', 'nPr', 'PSE',
  # G12
  'r', 'rta', 'RAD', '->RAD', 'RADIX,', 'RADIX.', 'RANDOM', 'RMDR',
  # G13
  'RND', 'RPN', 'RTN', 'Rv', 'R^', 'SEED', 'SGN', 
  # G14
  'STOP',
  # G15
  'sx', 'sy', 'x^2', 'sqrt', 'xroot', '\x-', '\x^', '!', 
  # G16
  '\x-w', 'x<>y', 'x!=y?', 'x<=y?', 'x<y?', 'x>y?', 'x>=y?',
  # G17
  'x=y?', 'x!=0?', 'x<=0?', 'x<0?', 'x>0?', 'x>=0?', 'x=0?', 'XOR', 
  # G18
  'xiy', 'x+yi', '\y-', '\y^', 'y^x',
);

our @with_address = (
  # G8
  'GTO',
  # G15
  'XEQ',
);

our @with_digits = (
  # G5
  'CF', 
  # G7
  'ENG',
  # G8
  'FIX', 'FS?',
  # G13
  'SCI', 'SF',
);

our @with_variables = (
  #G9
  'INPUT',  # HP35s bug -> INVALID (I)
  # G10
  'LBL',
);

# 14-22
our @with_indirects = (
  # G3
  '$FN_d',
  # G7
  'DSE',
  # G8
  'FN=',
  # G10
  'ISG',
  # G12
  'RCL', 'RCL+', 'RCL-', 'RCL*', 'RCL/', 'RMDR',
  # G14
  'SOLVE', 'STO', 'STO+', 'STO-', 'STO*', 'STO/',
  # G15
  'VIEW',
  # G16
  'x<>', 
);

our @expressions = (
  # G7
  'EQN', 
);

our @functions = (
  # G2
#  'INV',
  # G4
  'ABS', 'ACOS', 'ACOSH',
#  'ALOG',
  'ARG', 'ASIN', 'ASINH', 'ATAN',
  # G5
  'ATANH', '->°C',
  # G6
  '->CM', 'COS', 'COSH', '->DEG',
  # G8
#  'EXP',
  '->°F', '->GAL', 
  # G9
#  'IDIV', 'INV', 
  # G10
  'ISG',
  # G12
  'RMDR',
  # G14
  'SIN', 'SINH',
#  'SQ', 'SQRT',
  # G15
  'TAN', 'TANH',
  # G16
#  'XROOT',
);

our @register = (
  'REGX', 'REGY', 'REGZ', 'REGT',
);

# Override constructor
sub new {
  my $class = shift;
  
  # Call the constructor of the parent class
  my $self = $class->SUPER::new(@_);

  # A symbol represents a value, which can be a variable, address label, 
  # or an operand to an assembly instruction and directive
  # store predefined symbols
  my %variables = map { $_ => 'variable' } 'A'..'Z', @register;
  my %directives = map { $_ => 'directive' } @directives, @languages, @predefined;
  my %opcodes  = map { $_ => 'opcode' } @instructions, @with_address, @with_digits, @with_variables, @with_indirects, @expressions, @functions;
  $self->{_symbols} = { %variables, %directives, %opcodes };

  # Labels allow you to name the positions of specific instructions
  $self->{_labels} = undef;

  return $self;
}

=head1 METHODS

The following methods will be used to build the grammatical structure.

=cut

sub parse {
  my $self = shift;

  # model directive
  my $language = $self->parse_model;

  # list of segments
  my $result = $self->sequence_of(
    sub {
      $self->parse_segment;
    },
  )
  or
    $self->fail( "Expecting SEGMENT keyword" );

  # convert the array_ref to a hash_ref
  my $ref = { };
  foreach ( @$result ) {
    my ($key, $value) = each %$_;
    $ref->{$key} = $value;
  }

  # end directive
  my $start = $self->parse_end;
  
  my $root = {
    model     => $language,
    segments  => $ref,
    labels    => $self->{_labels},
  };
  $root->{startaddr} = $start if $start;
  return $root;
}

sub parse_model
{
  my $self = shift;

  # check if model is defined
  $self->maybe_expect( qr/MODEL\b/i ) or
    $self->fail("Model must be specified first");

  # check if language is defined
  my $result;
  eval { $result = $self->token_kw_icase( @languages ) };
  defined $result or
    $self->fail("Missing or illegal language ID");

  # skip whitespace characters and any comments
  $self->skip_ws;

  return $result;
}

sub parse_segment
{
  my $self = shift;

  my $result;
  my $name;
  my $type;

  # SEGMENT ...
  $self->expect( qr/SEGMENT\b/i );
  $self->commit;

  # SEGMENT [name] type
  eval { $type = $self->token_kw_icase( @segments ) };
  unless ( $type ) {
    # SEGMENT name type
    $name = $self->token_ident;
    $type = $self->token_kw_icase( @segments );
  }
    
  # call specific segment type
  if ( $type =~ /DATA/i ) {
    $result = $self->scope_of(
      undef,
      sub { $self->parse_data_block( $name ) },
      qr/ENDS/i
    );
  }
  elsif ( $type =~ /CODE/i ) {
    $result = $self->scope_of(
      undef,
      sub { $self->parse_code_block( $name ) },
      qr/ENDS/i
    );
  }
  elsif ( $type =~ /STACK/i ) {
    $result = $self->scope_of(
      undef,
      sub { $self->parse_stack_block( $name ) },
      qr/ENDS/i
    );
  }

  if ( $name ) {
    $self->maybe_expect( $name ) or
      $self->fail( "Unmatched ENDS" );
  }
  
  return $result;
}

sub parse_data_block {
  my $self  = shift;
  my $ident = shift || '_DATA';
  my $type  = 'data';
  
  $ident = uc $ident;
  # check if symbol already exists
  if ( defined $self->{_symbols}->{$ident} ) {
    $self->fail_from(
      $self->_find_before($ident),
      $self->{_symbols}->{$ident} eq $type
        ?
      "Symbol already defined"
        :
      "Symbol already different kind"
    )
  }

  my $result = $self->sequence_of(
    sub {
      $self->commit;
      $self->parse_data_statement;
    },
  )
  or
    return undef;

  # convert the array_ref to a hash_ref
  my $ref = { };
  foreach ( @$result ) {
    my ($key, $value) = each %$_;
    $ref->{$key} = $value;
  }

  # create new entry
  my $entry = {
    $ident => {
      type        => $type,
      definitions => $ref,
    }
  };

  # insert symbol into global symbol table
  $self->{_symbols}->{$ident} = $type;

  return $entry;
}

sub parse_data_statement {
  my $self = shift;
  my $type = 'equation';

  my $ident = $self->token_ident;
  my $fail_pos = $self->pos - length $ident;

  # check if new segment is defined or end has been reached
  if ( $ident =~ /^(?:SEGMENT|END)$/ ) {
    $self->commit;
    $self->fail_from($fail_pos, "Open segment");
  }

  # test if symbol already exists
  if ( defined $self->{_symbols}->{$ident} ) {
    $self->fail_from(
      $fail_pos, 
      $self->{_symbols}->{$ident} eq $type
        ?
      "Symbol already defined"
        :
      "Symbol already different kind"
    )
  };
  $self->commit;

  defined $self->maybe_expect( qr/EQU/i ) or
    $self->fail( "Expecting segment or group quantity" );

  my $value;
  $value = $self->any_of(
    sub { $self->token_number },
    sub { $self->token_string },
    sub { 0 },
  )
  or
    $self->fail( "Need expression" );

  # test if value has unknown character
  $fail_pos = $self->pos;
  my @fragments = split unknown_equ_chars, $value;
  my $diff = length($value) - length($fragments[0]);
  ($diff == 0) or
    $self->fail_from( $fail_pos - $diff - 1, "Unknown character" );

  # create new entry
  my $entry = {
    $ident => {
      type  => $type,
      value => $value,
    }
  };

  # insert symbol into global symbol table
  $self->{_symbols}->{$ident} = $type;

  return $entry;
}

sub parse_code_block {
  my $self  = shift;
  my $ident = shift || '_TEXT';
  my $type  = 'code';

  $ident = uc $ident;
  # check if symbol already exists
  if ( defined $self->{_symbols}->{$ident} ) {
    $self->fail_from(
      $self->_find_before($ident),
      $self->{_symbols}->{$ident} eq $type
        ?
      "Symbol already defined"
        :
      "Symbol already different kind"
    )
  }

  # call each code line
  my @tags = ();
  my $result = $self->sequence_of(
    sub {
      $self->commit;
      push @tags, $self->any_of(
        sub { $self->parse_label; },
        sub { 0 },
      );
      $self->parse_code_statement;
    }
  )
  or
    return undef;
  
  # insert the tags into global label table
  for (my $i = 0; $i < @tags; $i++ ) {
    my $key = $tags[$i] or
      next;
    # set the array index
    $self->{_labels}->{$key} = {
      type      => 'near',
      segment   => $ident,
      statement => $i,
    }
  }

  # create new entry
  my $entry = {
    $ident => {
      type        => $type,
      statements  => $result,
    }
  };
  
  # insert symbol into global symbol table
  $self->{_symbols}->{$ident} = $type;

  return $entry;
}

sub parse_code_statement {
  my $self = shift;

  my $mnemonic;
  my $vector;
  my $binary;
  my $octal;
  my $hex;
  my $complex;
  my $decimal;
  my $variable;
  my $statement;

  my $ret = $self->any_of(
    sub {
      $mnemonic = $self->token_kw_operation(
        @instructions,
        @with_address,
        @with_variables,
        @with_digits,
        @with_indirects, 
        @expressions,
        @functions,
        @register,
      )
    },
    # [1,2] [3,4,5]
    sub { $vector   = $self->generic_token(vector => qr/\[[\-\d\.e]+,[\-\d\.e]+(?:,[\-\d\.e]+)?\]/, sub { $_[1] } ) },
    # 0110b
    sub { $binary   = $self->generic_token(binary => qr/[01]+b/, sub { $_[1] } ) },
    # 7012o
    sub { $octal    = $self->generic_token(octal => qr/[0-7]+o/, sub { $_[1] } ) },
    # 12ABh
    sub { $hex      = $self->generic_token(hex => qr/[\dA-F]+h/, sub { $_[1] } ) },
    # 1i2 3t4
    sub { $complex  = $self->generic_token(comlex => qr/[\-\d\.e]+[it][\-\d\.e]+/, sub { $_[1] } ) },
    # 1 2.3 4e5 -6 7e-1
    sub { $decimal  = $self->generic_token(number => qr/[\-\d\.e]+d?/, sub { $_[1] } ) },
    sub { undef },
  );
  defined $ret or
    $self->fail( "Illegal instruction" );
  
  # get current position in str for "fail_from"
  my $pos = $self->pos;
  my ($line) = $self->where;
  $self->commit;

  if ( defined $mnemonic ) {

    my $operand;
    if ( grep { $_ eq $mnemonic } @instructions, @functions, @register ) {
      # instructions without an operand
      $statement = {
        $mnemonic => {
          type => 'instruction',
        }
      };
    }
    else {
      if ( grep { $_ eq $mnemonic } @with_address ) {
        # instructions with an address: GTO and XEQ
        eval { $operand = $self->token_ident } or
          $self->fail( "Illegal origin address" );

        $statement = {
          $mnemonic => {
            type    => 'instruction',
          }
        };
        if ($operand =~ /[A-Z]\d{3}/) {
          $statement->{$mnemonic}->{address} = $operand;
        } else {
          $statement->{$mnemonic}->{label} = uc $operand;
        };
      }
      elsif ( grep { $_ eq $mnemonic } @with_variables ) {
        # instructions with a variable: LBL and INPUT
        $operand = $self->generic_token( variable => qr/[A-Z]/ );
        $statement = {
          $mnemonic => {
            type      => 'instruction',
            variable  => $operand,
          }
        };
      }
      elsif ( grep { $_ eq $mnemonic } @with_digits ) {
        # instructions with a number 0 < n < 11: CF, FIX, ...
        $operand = $self->generic_token( number => qr/10|11|[0-9]/ );
        $statement = {
          $mnemonic => {
            type    => 'instruction',
            number  => $operand,
          }
        };
      }
      elsif ( grep { $_ eq $mnemonic } @with_indirects ) {
        # instructions with a (indirect) variable: VIEW, ...
        $operand = $self->generic_token( variable => qr/[A-Z]|(?:\([IJ]\))/ );
        $statement = {
          $mnemonic => {
            type      => 'instruction',
            variable  => $operand,
          }
        };
      }
      elsif ( grep { $_ eq $mnemonic } @expressions ) {
        # instructions with an expression: EQN

        $statement = {
          $mnemonic => {
            type      => 'instruction',
          }
        };
        # determine all current equations
        my @equations = ();
        foreach ( keys %{ $self->{_symbols} } ) {
          push @equations, $_ if $self->{_symbols}->{$_} eq 'equation';
        }
        # test if it is an equation
        if ( eval { $operand = $self->token_kw(@equations) } ) {
          $statement->{$mnemonic}->{equation} = $operand;
        }
        else {
          # it must be an quoted expression
          $operand = $self->generic_token( expression => qr/\'(.*?)\'/, sub { $1 } );
          $statement->{$mnemonic}->{expression} = $operand;
        }
      }
  
      @_ = $self->where;
      $line eq $_[0] or
        $self->fail_from( $pos, "Argument mismatch" );

    }
  }
  elsif ( defined $vector ) {
    $statement = {
      $vector => {
        type => 'vector',
      }
    };
  }
  elsif ( defined $binary ) {
    $statement = {
      $binary => {
        type => 'binary',
      }
    };
  }
  elsif ( defined $octal ) {
    $statement = {
      $octal => {
        type => 'octal',
      }
    };
  }
  elsif ( defined $hex ) {
    $statement = {
      $hex => {
        type => 'hex',
      }
    };
  }
  elsif ( defined $complex ) {
    $statement = {
      $complex => {
        type => 'complex',
      }
    };
  }
  elsif ( defined $decimal ) {
    $statement = {
      $decimal => {
        type => 'decimal',
      }
    };
  }
  elsif ( defined $variable ) {
    $statement = {
      $variable => {
        type => 'variable',
      }
    };
  }

  $self->skip_ws;
  @_ = $self->where;
  $line ne $_[0] or
    $self->fail("Extra characters on line");

  return $statement;
}

sub parse_label {
  my $self = shift;
  my $type = 'label';
  my $ident;

  $ident = $self->expect( qr/\w+:/ );
  $self->commit;
  my $fail_pos = $self->pos - length $ident;

  # check if symbol starts with number
  $ident !~ /^\d/ or
    $self->fail_from(
      $fail_pos,
      "Labels can't start with numeric characters"
    );

  # check if symbol looks like an address
  $ident !~ /^[A-Z]\d{3}:$/ or
    $self->fail_from(
      $fail_pos,
      "Illegal segment address"
    );

  $ident =~ s/://;
  $ident = uc $ident;

  # check if symbol already exists
  if ( defined $self->{_symbols}->{$ident} ) {
    $self->fail_from(
      $fail_pos,
      $self->{_symbols}->{$ident} eq $type
        ?
      "Symbol already defined"
        :
      "Symbol already different kind"
    )
  }

  # insert symbol into global symbol table
  $self->{_symbols}->{$ident} = $type;

  return $ident;
}

sub parse_stack_block
{
  my $self  = shift;
  my $ident = shift || 'STACK';
  my $type  = 'stack';

  $ident = uc $ident;
  # check if symbol already exists
  if ( defined $self->{_symbols}->{$ident} ) {
    $self->fail_from(
      $self->_find_before($ident),
      $self->{_symbols}->{$ident} eq $type
        ?
      "Symbol already defined"
        :
      "Symbol already different kind"
    )
  }

  my $result = $self->sequence_of(
    sub {
      $self->commit;
      $self->parse_stack_statement;
    },
  )
  or
    return undef;

  # convert the array_ref to a hash_ref
  my $ref = { };
  foreach ( @$result ) {
    my ($key, $value) = each %$_;
    $ref->{$key} = $value;
  }

  # create new entry
  my $entry = {
    $ident => {
      type        => $type,
      assignments => $ref,
    }
  };

  # insert symbol into global symbol table
  $self->{_symbols}->{$ident} = $type;

  return $entry;
}

sub parse_stack_statement
{
  my $self = shift;
  my $type = 'register';

  my $ident = $self->token_kw( @register );
  $self->commit;

  defined $self->maybe_expect( qr/SET/i ) or
    $self->fail( "Expecting segment or group quantity" );

  my $value;
  eval { $value = $self->token_number };
  defined $value or
    $self->fail( "Need expression" );

  # create new entry
  my $entry = {
    $ident => {
      type  => $type,
      value => $value,
    }
  };

  return $entry;
}

sub parse_end
{
  my $self = shift;

  # error, if at the end of input
  $self->at_eos and
    $self->fail( "Unexpected end of file (no END directive)" );
  
  # error, if statements outside of any segment
  $self->maybe_expect( qr/END\b/i ) or
    $self->fail( "Code or data emission to undeclared segment" );
  
  # determine all current labels
  my @labels = ();
  foreach ( keys %{ $self->{_symbols} } ) {
    push @labels, $_ if $self->{_symbols}->{$_} eq 'label';
  }

  # get the startaddress if present
  my $startaddress = $self->any_of(
    sub { $self->token_kw_icase( @labels ) },
    sub { 0 },
  );

  # ignore any data after END
  $self->substring_before( qr/$/s );
  
  return uc $startaddress;
}

=head2 $keyword = $parser->token_kw_icase( @keywords )

Expects to find a keyword, and consumes it. A keyword is defined as an
identifier which is exactly one of the literal values passed in.
This method works case insensitiv.

=cut

sub token_kw_icase
{
  my $self = shift;
  my @acceptable = @_;

  $self->skip_ws;

  my $pos = pos $self->{str};

  defined( my $kw = $self->token_ident ) or
    return undef;

  grep { /^$kw$/i } @acceptable or
    pos($self->{str}) = $pos, $self->fail( "Expected any of ".join( ", ", @acceptable ) );

  return $kw;
}

=head2 $keyword = $parser->token_kw_operation( @keywords )

Expects to find a operation, and consumes it. A operation is defined as an
identifier which is exactly one of the literal values passed in.

=cut

sub token_kw_operation
{
  my $self = shift;
  my @acceptable = @_;

  $self->skip_ws;

  my $pos = pos $self->{str};
  
  defined( my $kw = $self->generic_token( operation => pattern_operation, ) ) or
    return undef;

  grep { $_ eq $kw } @acceptable or
    pos($self->{str}) = $pos, $self->fail( "Expected any of ".join( ", ", @acceptable ) );

  return $kw;
}

=head2 $str = $parser->token_string

Expects to find a quoted string, and consumes it. The string should be quoted
using C<"> or C<'> quote marks.

The content of the quoted string can not contain special characters.

=cut

sub token_string
{
  my $self = shift;

  $self->fail( "Expected string" ) if $self->at_eos;

  my $pos = pos $self->{str};

  $self->skip_ws;
  $self->{str} =~ m/\G($self->{patterns}{string_delim})/gc or
     $self->fail( "Expected string delimiter" );

  my $delim = $1;

  $self->{str} =~ m/
    \G(
      (?:
         \\.              # symbolic escape
        |[^\\$delim]+     # plain chunk
      )*?
    )$delim/gcix or
      pos($self->{str}) = $pos, $self->fail( "Expected contents of string" );

  my $string = $1;

  return $string;
}

=head2 $position = $parser->_find_before( $literal )

Private subroutine to search backwards a substring inside the parser-string.

=cut

sub _find_before
{
  my $self    = shift;
  my $substr  = reverse shift;

  exists $self->{reverse_str} or
    $self->{reverse_str} = reverse $self->{str};
  
  exists $self->{length} or
    $self->{length} = length $self->{str};

  my $pos = $self->{length} - $self->pos;
  my $idx = index $self->{reverse_str}, $substr, $pos;

  return $idx > 0
      ?
    $self->{length} - $idx - length $substr
      :
    $self->pos;
}

1;
