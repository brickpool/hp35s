#!/usr/bin/perl
#
# (c) 2019, 2020 brickpool
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
#   - the directive DISPLAY, LOCALS, NOLOCALS and RADIX and %TITLE
#     are not implemented
#   - only the polish notation mode is supported
#   - Thousand separator operations are not implemented

use strict;
use warnings;

=head1 NAME

C<HpcParser> - simple recursive-descent one-pass assembler parser for HP calculators

=cut

package Parser::HPC;
use strict;
use warnings;

use Exporter;
our @EXPORT = qw(
  @constants
  @instructions
  @with_address
  @with_digits
  @with_variables
  @with_indirects
  @expressions
  @functions
  @register
);
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
use constant pattern_ident      => qr/[[:alpha:]@_\$?][[:alnum:]@_\$?]{0,246}/;

my @directives = (
  'DISPLAY', 'ENDS', 'END', 'EQU', 'LOCALS', 'NOLOCALS', 'MODEL', 'RADIX', 'SEGMENT', 'SET', '%TITLE',
);

# Pre defined text equates
my @predefined = (
  '??date', '??time',
);

my @languages = (
  'P35S',
);

my @segments = (
  'DATA', 'CODE', 'STACK',
);

our @constants = (
  'pi',   # Pi (3.1416)
  'i',    # Im (0.0000i1.0000)
  
  'c',    # Speed of light in vacuum
  'g',    # Standard acceleration of gravity
  'G',    # Newtonian constant of gravitation
  'Vm',   # Molar volume of ideal gas
  'NA',   # Avogadro constant
  'Rb',   # Rydberg constant
  'eV',   # Elementary charge
  'me',   # Electron mass
  'mp',   # Proton mass
  'mn',   # Neutron mass
  'mu',   # Muon mass
  'k',    # Boltzmann constant
  'h',    # Planck constant
  'hbar', # Planck constant over 2 pi
  'Ph0',  # Magnetic flux quantum
  'a0',   # Bohr radius
  'e0',   # Electric constant
  'R',    # Molar gas constant
  'F',    # Faraday constant
  'u',    # Atomic mass constant
  'u0',   # Magnetic constant
  'uB',   # Bohr magneton
  'uN',   # Nuclear magneton
  'up',   # Proton magnetic moment
  'ue',   # Electron magnetic moment
  'un',   # Neutron magnetic moment
  'uu',   # Muon magnetic moment
  're',   # Classical electron radius
  'Z0',   # Characteristic impendence of vacuum
  'lc',   # Compton wavelength
  'lcn',  # Neutron Compton wavelength
  'lcp',  # Proton Compton wavelength
  'a',    # Fine structure constant
  'z',    # Stefan�Boltzmann constant
  't',    # Celsius temperature
  'atm',  # Standard atmosphere
  'gp',   # Proton gyromagnetic ratio
  'C1',   # First radiation constant
  'C2',   # Second radiation constant
  'G0',   # Conductance quantum
  'e',    # The base number of natural logarithm
);

our @instructions = (
  # G1
  '+/-', '+', '-', '*', '/',
  # G2
  '1/x', '10^x', '%', '%CHG', 'Z+', 'Z-',
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
  'RCL', 'RCL+', 'RCL-', 'RCL*', 'RCL/',
  # G14
  'SOLVE', 'STO', 'STO+', 'STO-', 'STO*', 'STO/',
  # G15
  'VIEW',
  # G16
  'x<>',
);

our @expressions = (
  # G7
  'eqn',
);

our @functions = (
  # G2
#  'INV',
  # G4
  'ABS', 'ACOS', 'ACOSH',
#  'ALOG',
  'ARG', 'ASIN', 'ASINH', 'ATAN',
  # G5
  'ATANH', '->�C',
  # G6
  '->CM', 'COS', 'COSH', '->DEG',
  # G8
#  'EXP',
  '->�F', '->GAL',
  # G9
#  'IDIV', 'INV',
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

# EQN character
my $character = {
  '\^c'   => '02',  # Constant 'lamda c'
  '\^e'   => '03',  # Constant 'e'
  '\^g'   => '04',  # Constant 'g'
  '\^h'   => '05',  # Constant 'h'
  '\^m'   => '06',  # Constant 'me'
  '\^n'   => '07',  # Constant 'mn'
  '\^p'   => '08',  # Constant 'mp'
  '\^r'   => '09',  # Constant 're'
  '\^t'   => '0a',  # Constant 'atm'
  '\015'  => '0f',  # Constant 'NA'
  '\016'  => '10',  # Constant 'c'
  '\017'  => '11',  # Constant 'F'
  '\018'  => '12',  # Constant 'G'
  '\^k'   => '13',  # Constant 'k'
  '\020'  => '14',  # Constant 'R'
  '\021'  => '15',  # Constant 'G0'
  '\023'  => '17',  # Constant 'h-bar'
  '\024'  => '18',  # Constant 't'
  '\Ga'   => '19',  # Constant 'alpha'
  '\Gl'   => '1a',  # Constant 'lamda c'
  '\O/'   => '1b',  # Constant 'Phi 0'
  '\Gg'   => '1c',  # Constant 'gamma p'
  '\oo'   => '1e',  # Constant 'R infinity'
  '\Ge'   => '1f',  # Constant 'epsilon 0'
  ' '     => '20',  # Space
  '!'     => '21',  # Factorial symbol
  '%'     => '25',  # Percent symbol '%CHG'
  '\^-'   => '26',  # Sign symbol '+/-'
  '('     => '28',  # Function bracket
  ')'     => '29',  # Function bracket
  '+'     => '2b',  # Addition sign
  '-'     => '2d',  # Substraction sign
  '0'     => '30',  # Number '0'
  '1'     => '31',  # Number '1'
  '2'     => '32',  # Number '2'
  '3'     => '33',  # Number '3'
  '4'     => '34',  # Number '4'
  '5'     => '35',  # Number '5'
  '6'     => '36',  # Number '6'
  '7'     => '37',  # Number '7'
  '8'     => '38',  # Number '8'
  '9'     => '39',  # Number '9'
  '='     => '3d',  # Equal symbol
  'A'     => '41',  # Variable 'A'
  'B'     => '42',  # Variable 'B'
  'C'     => '43',  # Variable 'C'
  'D'     => '44',  # Variable 'D'
  'E'     => '45',  # Variable 'E'
  'F'     => '46',  # Variable 'F'
  'G'     => '47',  # Variable 'G'
  'H'     => '48',  # Variable 'H'
  'I'     => '49',  # Variable 'I'
  'J'     => '4a',  # Variable 'J'
  'K'     => '4b',  # Variable 'K'
  'L'     => '4c',  # Variable 'L'
  'M'     => '4d',  # Variable 'M'
  'N'     => '4e',  # Variable 'N'
  'O'     => '4f',  # Variable 'O'
  'P'     => '50',  # Variable 'P'
  'Q'     => '51',  # Variable 'Q'
  'R'     => '52',  # Variable 'R'
  'S'     => '53',  # Variable 'S'
  'T'     => '54',  # Variable 'T'
  'U'     => '55',  # Variable 'U'
  'V'     => '56',  # Variable 'V'
  'W'     => '57',  # Variable 'W'
  'X'     => '58',  # Variable 'X'
  'Y'     => '59',  # Variable 'Y'
  'Z'     => '5a',  # Variable 'Z'
  '['     => '5b',  # Vector bracket
  '\092'  => '5c',  # Base binary 'b'
  'b'     => '5c',
  ']'     => '5d',  # Vector bracket
  '^'     => '5e',  # Exponent 'y^x'
  '\096'  => '60',  # Base octal 'o'
  'o'     => '60',
  '\_b'   => '7b',  # Linear regression 'b'
  '\125'  => '7d',  # Standard Deviation 's'
  's'     => '7d',
  '\128'  => '80',  # Summation statistics 'n'
  'n'     => '80',
  '\:-'   => '81',  # Division sign
  '/'     => '81',
  '\.x'   => '82',  # Multiplication sign
  '*'     => '82',
  '\GS'   => '85',  # Summation statistics 'Sigma x'
  '\pi'   => '87',  # Greek small 'pi'
  '\_y'   => '8c',  # Standard Deviation 'sigma y'
  'y'     => '8c',
  '\->'   => '8d',  # Unit Conversion '->l'
  '\_x'   => '8e',  # Standard Deviation 'sigma x'
  'x'     => '8e',
  '\Gm'   => '8f',  # Constant '��'
  '�'     => '8f',
  '\145'  => '91',  # Summation statistics 'Sigma x^2'
  '�'     => '91',
  '\^o'   => '94',  # Degree '->�F'
  '�'     => '94',
  '\157'  => '9d',  # Constant 'sigma'
  '\Gh'   => '9e',  # Complex small 'theta'
  '\167'  => 'a7',  # Constant 'atm'
  '\171'  => 'ab',  # Linear regression 'r'
  'r'     => 'ab',
  '\Gs'   => 'ae',  # Standard Deviation 'sigma x'
  '\x-'   => 'af',  # Mean 'x-bar'
  '\y-'   => 'b0',  # Mean 'y-bar'
  '\x^'   => 'b1',  # Linear estimation 'x-hat'
  '\y^'   => 'b2',  # Linear estimation 'y-hat'
  '\179'  => 'b3',  # Linear regression 'm'
  'm'     => 'b3',
  '\^1'   => 'b8',  # Constant 'C1'
  '\^2'   => 'b9',  # Constant 'C2'
  '\_w'   => 'c1',  # Mean 'x-bar w'
  'w'     => 'c1',
  '\^B'   => 'c5',  # Constant '�B'
  '\^C'   => 'c6',  # Constant 'C1'
  '\^G'   => 'ca',  # Constant 'G0'
  '\^N'   => 'd1',  # Constant 'NA'
  '\^a'   => 'd8',  # Constant 'a0'
  '\^u'   => 'e3',  # Constant 'u'
  '\231'  => 'e7',  # Exponent 'E'
  'e'     => 'e7',
  '\235'  => 'eb',  # Base hexadecimal 'h'
  'h'     => 'eb',
  '\im'   => 'ec',  # Complex script small 'i'
  'i'     => 'ec',
  '\^R'   => 'ef',  # Constant 'R infinity'
  '\^V'   => 'f3',  # Constant 'Vm'
  '\^Z'   => 'f7',  # Constant 'Z0'
  '\252'  => 'fc',  # Base decimal 'd'
  'd'     => 'fc',
  '\;,'   => 'fd',  # comma ',' in function
  ','     => 'fd',
  '\|>'   => 'ff',  # 'STO' in mode algebraic
};


# Override constructor
sub new {
  my $class = shift;
  
  # Call the constructor of the parent class
  my $self = $class->SUPER::new(@_);

  # A symbol represents a value, which can be a variable, address label, 
  # or an operand to an assembly instruction and directive
  # store predefined symbols
  my %constants   = map { $_ => 'constant'  } @constants;
  my %variables   = map { $_ => 'variable'  } 'A'..'Z',
                                              @register;
  my %directives  = map { $_ => 'directive' } @directives,
                                              @languages;
  my %opcodes     = map { $_ => 'opcode'    } @instructions,
                                              @with_address,
                                              @with_digits,
                                              @with_variables,
                                              @with_indirects,
                                              @expressions,
                                              @functions;
  my %equations  = map { $_ => 'equation'   } @predefined;
  $self->{_symbols} = { %constants, %variables, %directives, %opcodes, %equations };

  # Labels allow you to name the positions of specific instructions
  $self->{_labels} = undef;

  return $self;
}

=head1 METHODS

The following methods will be used to build the grammatical structure.

=cut

sub parse {
  my $self = shift;

  # %title directive
  my $title = $self->maybe(
    sub { $self->parse_title }
  );

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
  $root->{title}      = $title if $title;
  $root->{startaddr}  = $start if $start;
  return $root;
}

sub parse_title {
  my $self = shift;

  # check if title is defined
  $self->expect( qr/%TITLE\b/i );
  $self->commit;
  
  # get quoted string
  my $pos = $self->pos;
  my $result;
  eval { $result = $self->token_string };

  # check if quoted string is present
  defined $result
    or
  $self->fail("Need quoted string");

  # validate quoted string (the built-in variable '@-' holds the start position)
  $result !~ /\s*\n/
    or
  $self->fail_from($pos + $-[0]+1, "Missing end quote");
  
  # skip whitespace characters and any comments
  $self->skip_ws;

  return $result;
}


sub parse_model {
  my $self = shift;

  # check if model is defined
  $self->maybe_expect( qr/MODEL\b/i )
    or
  $self->fail("Model must be specified first");

  # check if language is defined
  my $result;
  eval { $result = $self->token_kw_icase( @languages ) };
  defined $result
    or
  $self->fail("Missing or illegal language ID");

  # skip whitespace characters and any comments
  $self->skip_ws;

  return $result;
}


sub parse_segment {
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
  SWITCH: for ($type) {
    /DATA/i && do {
      $result = $self->scope_of(
        undef,
        sub { $self->parse_data_block( $name ) },
        qr/ENDS/i
      );
      last;
    };
    /CODE/i && do {
      $result = $self->scope_of(
        undef,
        sub { $self->parse_code_block( $name ) },
        qr/ENDS/i
      );
      last;
    };
    /STACK/i && do {
      $result = $self->scope_of(
        undef,
        sub { $self->parse_stack_block( $name ) },
        qr/ENDS/i
      );
      last;
    };
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
  $fail_pos = $self->pos - length($value);

  # input | normal  | start  | middle    | end     | unknown
  # ----- | ------- | ------ | --------- | ------- | -------
  # `\`   | start   | normal | unknown   | unknown | -
  # `\d`  | -       | middle | end       | normal  | -
  # `\D`  | -       | end    | unknown   | normal  | -
  my $state = 'normal';
  my $char = '';
  foreach (split //, $value)
  {
    $char .= $_;
    SWITCH: {
      $state =~ /normal/ && do {
        if (/\\/) {
          $state = 'start';
          $char = '\\';
        }
        else {
          exists $character->{$char} or
            $self->fail_from( $fail_pos - length($char), "Unknown character" );
          $char = '';
        }
        last;
      };
      $state =~ /start/ && do {
        if (/\\/) {
          $state = 'normal';
          exists $character->{$char} or
            $self->fail_from( $fail_pos - 1, "Invalid character" );
          $char = '';
        }
        elsif (/\d/) {
          $state = 'middle';
        }
        else {
          $state = 'end';
        }
        last;
      };
      $state =~ /middle/ && do {
        if (/\d/) {
          $state = 'end';
        }
        else {
          $state = 'unknown';
        }
        last;
      };
      $state =~ /end/ && do {
        if (/\\/) {
          $state = 'unknown';
        }
        else {
          $state = 'normal';
          exists $character->{$char} or
            $self->fail_from( $fail_pos - length($char), "Unknown character sequence" );
          $char = '';
        }
        last;
      };
      DEFAULT: {
        $self->fail_from( $fail_pos - length($char), "Invalid character sequence" );
      }
    }
    $fail_pos++;
  }
  $state =~ /normal/ or
    $self->fail_from( $fail_pos - length($char) - 1, "Argument mismatch" );

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
      push @tags, $self->sequence_of(
        sub { $self->parse_label; },
      );
      $self->parse_code_statement;
    }
  )
    or
  return undef;
  
  # insert the tags into global label table
  for (my $i = 0; $i < @tags; $i++ ) {
    foreach my $key ( @{ $tags[$i] }) {
      # set the array index
      $self->{_labels}->{$key} = {
        type      => 'near',
        segment   => $ident,
        statement => $i,
      }
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
        @constants,
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
  defined $ret
    or
  $self->fail( "Illegal instruction" );
  
  # get current position in str for "fail_from"
  my $pos = $self->pos;
  my ($line) = $self->where;
  $self->commit;

  if ( defined $mnemonic ) {

    my $operand;
    if ( grep { $_ eq $mnemonic } @constants ) {
      # constants
      $statement = {
        $mnemonic => {
          type => 'constant',
        }
      };
    }
    elsif ( grep { $_ eq $mnemonic } @instructions, @functions, @register ) {
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
        eval { $operand = $self->generic_token(label => qr/\@{0,2}\w+/, sub { $_[1] } ) } or
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

  $ident = $self->expect( qr/\@{0,2}\w+:/ );
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
  defined $value
    or
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
  $self->maybe_expect( qr/END\b/i )
    or
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

  defined( my $kw = $self->token_ident )
    or
  return undef;

  grep { /^$kw$/i } @acceptable
    or
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
  
  defined( my $kw = $self->generic_token( operation => pattern_operation, ) )
    or
  return undef;

  grep { $_ eq $kw } @acceptable
    or
  pos($self->{str}) = $pos, $self->fail( "Expected any of ".join( ", ", @acceptable ) );

  return $kw;
}

=head2 $str = $parser->token_string

Expects to find a quoted EQN string, and consumes it. The string should be quoted
using C<"> or C<'> quote marks.

The content of the quoted string can not contain special characters.

=cut

sub token_string
{
  my $self = shift;

  $self->fail( "Expected string" ) if $self->at_eos;

  my $pos = pos $self->{str};

  $self->skip_ws;
  $self->{str} =~ m/\G($self->{patterns}{string_delim})/gc
    or
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

  exists $self->{reverse_str}
    or
  $self->{reverse_str} = reverse $self->{str};
  
  exists $self->{length}
    or
  $self->{length} = length $self->{str};

  my $pos = $self->{length} - $self->pos;
  my $idx = index $self->{reverse_str}, $substr, $pos;

  return
    $idx > 0
      ?
    $self->{length} - $idx - length $substr
      :
    $self->pos;
}

1;
