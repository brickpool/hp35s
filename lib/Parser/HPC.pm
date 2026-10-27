package Parser::HPC;
# ABSTRACT: Simple recursive-descent 1-pass assembler parser for HP calculators

# ------------------------------------------------------------------------
# Boilerplate
# ------------------------------------------------------------------------

use strict;
use warnings;

use version;
our $VERSION = version->declare('v0.5.3');

# ------------------------------------------------------------------------
# Imports
# ------------------------------------------------------------------------

use Parser::MGC;
use HP35s::Charset qw(
  $character
);
use HP35s::Vocabulary qw(
  @constants
  @instructions
  @with_address
  @with_digits
  @with_variables
  @with_indirects
  @expressions
  @functions
  @register
  instruction_kind
);
use Parser::HPC::Vocabulary qw(
  @directives
  @predefined
  @languages
  @segments
  @listings
  @modes
  @models
);
use Parser::HPC::Macro;

# -------------------------------------------------------------------------
# Parent class
# -------------------------------------------------------------------------

use parent 'Parser::MGC';

# -------------------------------------------------------------------------
# Define constants
# -------------------------------------------------------------------------

# overwrite existing patterns
use constant pattern_comment => qr/;.*\n/;
use constant pattern_ident   => qr/[[:alpha:]\@_\$?][[:alnum:]\@_\$?]{0,246}/;
use constant pattern_float   => qr/-?(?:\d*\.\d+|\d+\.)(?:e-?\d+)?|-?\d+e-?\d+/;

# new patterns
use constant pattern_operation => qr/[^\s\(\)]+/;
use constant pattern_vector    => qr/\[[\-\d\.e]+,[\-\d\.e]+(?:,[\-\d\.e]+)?\]/;
use constant pattern_binary    => qr/[01]+b/;
use constant pattern_octal     => qr/[0-7]+o/;
use constant pattern_hex       => qr/[\dA-F]+h/;
use constant pattern_complex   => qr/[\-\d\.e]+[it][\-\d\.e]+/;
use constant pattern_decimal   => qr/-?\d+d\b/;
use constant pattern_label => qr/
  # \?\?nnnn and \@\@nnnn are reserved
  (?! (?: \?\? | \@\@ ) \d{4} (?= [\s:;] | \z ) )

  # \$, \?, \@ and \@\@ are not labels
  (?! (?: \$ | \? | \@\@? ) (?= [\s:;] | \z ) )

  [[:alnum:]_\@\$\?]+
/ixa;

# Macro flags
use constant {
  MACRO_NONE  => 0,
  MACRO_LOCAL => 1 << 0,
  MACRO_DUMMY => 1 << 1,
};

# -------------------------------------------------------------------------
# Constructor
# -------------------------------------------------------------------------

sub new {    # $parser (%args)
  my ($class, %args) = @_;
  
  # Call the constructor of the parent class
  my $self = $class->SUPER::new( %args );

  # Assign patterns for additional token types
  $self->{patterns}{$_} = $args{patterns}{$_} || $self->${\"pattern_$_"} 
    for qw( operation vector binary octal hex complex decimal label );

  # public parser attributes
  $self->{mode}     = 'IDEAL';    # IDEAL mode by default
  $self->{model}    = 0;          # TINY model by default
  $self->{title}    = undef;      # title is undef by default
  $self->{radix}    = 10;         # radix is decimal by default
  $self->{locals}   = 1;          # local label handling enabled by default
  $self->{language} = 'P35S';     # language is P35S by default

  # private parser attributes
  $self->{_macro}            = undef;
  $self->{_macro_name}       = undef;
  $self->{_track_source_ids} = 0;

  # A symbol represents a value, which can be a variable, address label, 
  # or an operand to an assembly instruction and directive
  # store predefined symbols
  
  my %constants   = map { $_ => 'constant' } 
                    map { $self->_canonical_symbol($_) }
                      @constants;
  my %variables   = map { $_ => 'variable' } 
                    map { $self->_canonical_symbol($_) }
                      'A'..'Z', @register;
  my %directives  = map { $_ => 'directive' }
                    map { $self->_canonical_symbol($_) } 
                      @directives, @languages, @segments,
                      @listings,  @modes, @models;
  my %opcodes     = map { $_ => 'opcode' }
                    map { $self->_canonical_symbol($_) } 
                      @instructions,  @with_address, @with_digits, 
                      @with_variables, @with_indirects, @expressions,
                      @functions;
  my %equations   = map { $_ => 'equation' }
                    map { $self->_canonical_symbol($_) } 
                      @predefined;
  $self->{symbols} = { %constants, %variables, %directives, %opcodes, 
    %equations };

  return $self;
}

# -------------------------------------------------------------------------
# Overload existing Methods
# -------------------------------------------------------------------------

sub from_string {    # $result ($str)
  my ($self, $source) = @_;
  return $self->SUPER::from_string($source) if $self->{_track_source_ids};

  my $macro_parser = Parser::HPC::Macro->new(
    patterns => { ident => $self->{patterns}{ident} },
  );
  my $parsed_source = $macro_parser->from_string($source);
  return $self->SUPER::from_string($parsed_source);
}

sub parse {    # $tree ()
  my $self = shift;

  # global header
  my $header = $self->parse_header;

  # list of segments
  my $result = $self->sequence_of(
    sub {
      my $end_of_scope = $self->maybe(sub {
        $self->token_kw_icase('END');
      }) || $self->at_eos;
      $self->fail('Illegal instruction')
        if $end_of_scope;
      $self->commit;

      $self->any_of(
        'parse_locals',
        'parse_radix',
        'parse_display',
        'parse_segment',
        sub {
          $self->commit;
          $self->fail('Code or data emission to undeclared segment');
        },
      );
    },
  ) or $self->fail( "Expecting SEGMENT keyword" );

  # end directive
  my $start = $self->parse_end;

  my $ast = {
    header   => $header,
    segments => $result,
  };
  $ast->{startaddr} = $start if $start;

  return $self->_prepare_ast($ast);
}

sub token_number {    # $value ()
  my $self = shift;
  my $value = $self->any_of(
    \&token_binary,
    \&token_octal,
    \&token_decimal,
    \&token_hex,
    sub {
      my $base = $self->{radix};
      if ( $base == 2 ) {
        return $self->generic_token(binary => qr/[01]+/,
          sub {
            no warnings 'portable';
            my $number = oct('0b' . $_[1]);
            $number -= 2**36 if $number >= 2**35;
            return $number;
          }
        );
      } 
      elsif ( $base == 8 ) {
        return $self->generic_token(octal => qr/[0-7]+/,
          sub {
            no warnings 'portable';
            my $number = oct('0' . $_[1]);
            $number -= 2**36 if $number >= 2**35;
            return $number;
          }
        );
      }
      elsif ( $base == 16 ) {
        return $self->generic_token(hex => qr/[\dA-F]+/,
          sub {
            no warnings 'portable';
            my $number = hex($_[1]);
            $number -= 2**36 if $number >= 2**35;
            return $number;
          }
        );
      } 
      return $self->SUPER::token_number;
    },
  );
  return $value;
}

sub token_string {    # $string ()
  my $self = shift;

  $self->fail( "Expected string" ) if $self->at_eos;

  my $pos = pos $self->{str};

  $self->skip_ws;
  $self->{str} =~ m/\G($self->{patterns}{string_delim})/gc
    or $self->fail( "Expected string delimiter" );

  my $delim = $1;

  $self->{str} =~ m/
    \G(
      (?:
         \\.              # symbolic escape
        |[^\\$delim]+     # plain chunk
      )*?
    )$delim/gcix
      or pos($self->{str}) = $pos, $self->fail( "Expected contents of string" );

  my $string = $1;

  return $string;
}

sub warn :method {
  my ($self, $message) = @_;
  Parser::MGC->can('warn') 
    ? $self->SUPER::warn( $message )
    : warn( Parser::MGC::Failure->new( $message, $self, $self->pos )->STRING );
}

# -------------------------------------------------------------------------
# New public Methods
# -------------------------------------------------------------------------

# parse methods

sub parse_header {    # \%header ()
  my $self = shift;

  my $sections = join '|' => ( @segments, 'END' );

  my $result = $self->scope_of(
    undef,
    sub {
      $self->sequence_of(
        sub {
          $self->commit;

          $self->any_of(
            'parse_title',
            'parse_mode',
            'parse_language',
            'parse_model',
            sub {
              $self->parse_display;
              return {};
            },
            sub {
              $self->parse_locals;
              return {};
            },
            sub {
              $self->parse_radix;
              return {};
            },
            sub {
              $self->commit;
              $self->fail('Illegal instruction');
            },
          );
        },
      );
    },
    qr/(?=(?:$sections)\b|\z)/i,
  );

  my $header = $result
    ? { map { %$_ } @$result }
    : {};

  $self->fail("Model must be specified first")
    unless exists $header->{model};

  $self->fail("Invalid model type")
    unless $header->{model} == 0;

  return $header;
}

sub parse_title {    # \%title ()
  my $self = shift;

  # %TITLE "title"
  $self->maybe_expect( qr/\%TITLE(?=[\s;]|\z)/i )
    or $self->fail('Expected %TITLE');
  $self->commit;

  # retrieve the state immediately after the commit
  my ($line, $col, $line_text) = $self->where;
  my $pos = $self->pos;

  # get quoted string (internally skips whitespace)
  my $title = $self->maybe( 'token_string' );
  length $title
    or $self->fail_from( $pos + 1, "Need quoted string" );

  # check whether we have left the line
  my ($new_line) = $self->where;
  if ( $line != $new_line ) {
    my $fail_pos = $pos + length($line_text) - $col;
    $self->fail_from( $fail_pos, "Missing end quote" );
  }
  $self->commit;

  # skip whitespace and ensure no extra characters remain on the line
  $self->skip_ws;
  my ($next_line) = $self->where;
  $line != $next_line
    or $self->fail( "Extra characters" );    # .. on line

  # The %TITLE statement may be used only once in a program
  $self->fail( 'Symbol already defined: %TITLE' )
    if defined $self->{title};
  
  $self->{title} = $title;
  return { 
    title => $self->{title}
  };
}

sub parse_display {    # \%display ()
  my $self = shift;

  # DISPLAY "message"
  $self->maybe_expect( qr/DISPLAY(?=[\s;]|\z)/i )
    or $self->fail("Expected DISPLAY" );
  $self->commit;

  # retrieve the state immediately after the commit
  my ($line, $col, $line_text) = $self->where;
  my $pos = $self->pos;

  # get quoted string (internally skips whitespace)
  my $display = $self->maybe( 'token_string' );
  length $display
    or $self->fail_from( $pos + 1, "Need quoted string" );

  # check whether we have left the line
  my ($new_line) = $self->where;
  if ( $line != $new_line ) {
    my $fail_pos = $pos + length($line_text) - $col;
    $self->fail_from( $fail_pos, "Missing end quote" );
  }
  $self->commit;

  # skip whitespace and ensure no extra characters remain on the line
  $self->skip_ws;
  my ($next_line) = $self->where;
  $line != $next_line
    or $self->fail( "Extra characters" );    # .. on line

  # display the message as a warning immediately
  $self->warn($display);

  return { 
    display => $display
  };
}

sub parse_mode {   # \%mode ()
  my $self = shift;

  my $mode = $self->token_kw_icase( @modes );
  $self->commit;

  # retrieve the state immediately after the commit
  my ($line) = $self->where;

  # skip whitespace and ensure no extra characters remain on the line
  $self->skip_ws;
  my ($next_line) = $self->where;
  $line != $next_line
    or $self->fail("Extra characters");

  $self->{mode} = $self->_canonical_symbol($mode);
  return { 
    mode => $self->{mode}
  };
}

sub parse_language {    # \%language ()
  my $self = shift;

  my $language = $self->maybe( sub { $self->token_kw_icase( @languages ) } ) 
    or $self->fail("Missing or illegal language ID");
  $self->commit;

  # retrieve the state immediately after the commit
  my ($line) = $self->where;

  # skip whitespace and ensure no extra characters remain on the line
  $self->skip_ws;
  my ($next_line) = $self->where;
  $line != $next_line
    or $self->fail("Extra characters");

  $self->{language} = $self->_canonical_symbol($language);
  return { 
    language => $self->{language}
  };
}

sub parse_model {    # \%model ()
  my $self = shift;

  $self->expect( qr/MODEL(?=\s)/i );
  $self->commit;

  # retrieve the state immediately after the commit
  my ($line) = $self->where;

  # parse the model ID
  my $model = $self->maybe( sub { $self->token_kw_icase( @models ) } );
  my ($model_line) = $self->where;
  defined $model && $line == $model_line
    or $self->fail("Invalid model type");
  $self->commit;

  # skip whitespace and ensure no extra characters remain on the line
  $self->skip_ws;
  my ($next_line) = $self->where;
  $line != $next_line
    or $self->fail("Extra characters");

  my %models = (
    TINY    => 0,
    SMALL   => 1,
    COMPACT => 2,
    MEDIUM  => 3,
    LARGE   => 4,
    HUGE    => 5,
  );
  $model = $self->_canonical_symbol($model);
  $self->{model} = $models{$model};
  return { 
    model => $self->{model}
  };
}

sub parse_radix {    # \%radix ()
  my $self = shift;

  # RADIX ..
  $self->maybe_expect( qr/RADIX(?=[\s;]|\z)/i )
    or $self->fail("Expected RADIX" );
  $self->commit;

  # retrieve the state immediately after the commit
  my ($line) = $self->where;

  # RADIX base
  my $result = $self->maybe_expect( qr/(?:2|8|10|16)(?=[\s;])/ )
    or $self->fail("Illegal radix");
  $self->commit;

  # skip whitespace and ensure no extra characters remain on the line
  $self->skip_ws;
  my ($next_line) = $self->where;
  $line != $next_line
    or $self->fail( "Extra characters" );    # .. on line

  $self->{radix} = 0+ $result;
  return { 
    radix => $self->{radix} 
  };
}

sub parse_locals {    # \%locals ()
  my $self = shift;
  my $type = 'locals';

  # [NO]LOCALS
  my $result = $self->expect(qr/(?:NOLOCALS|LOCALS)(?=[\s;])/i);
  $self->commit;

  # retrieve the state immediately after the commit
  my ($line) = $self->where;

  # skip whitespace and ensure no extra characters remain on the line
  $self->skip_ws;
  my ($next_line) = $self->where;
  $line != $next_line
    or $self->fail( "Extra characters" );    # .. on line

  $result = $self->_canonical_symbol($result);
  my $value = $self->{locals} = $result eq 'LOCALS' ? 1 : 0;

  return { 
    directive => {
      type  => $type,
      value => $value,
    }
  };
}

sub parse_segment {    # \%segment ()
  my $self = shift;

  # DATASEG or CODESEG or ..
  my $segment = $self->token_kw_icase( @segments );
  $self->commit;

  $segment = $self->_canonical_symbol($segment);
  my $sections = join '|' => ( @segments, 'END' );
  return $self->scope_of(
    undef, 
    sub { 
      SWITCH: for ($segment) {
        /DATASEG/ and return $self->parse_data_block; 
        /CODESEG/ and return $self->parse_code_block;
        /STACK/   and return $self->parse_stack_block;
      }
    },
    qr/(?=(?:$sections)\b|\z)/i
  );
}

sub parse_stack_block {    # \%block (|$ident)
  my $self  = shift;
  my $ident = shift || 'STACK';
  my $type  = 'stack';

  # insert symbol into global symbol table
  $ident = $self->_canonical_symbol($ident);
  $self->{symbols}{$ident} = $type;

  # call each stack line
  my $result = $self->sequence_of(
    sub {
      $self->commit;

      $self->any_of(
        sub {
          $self->parse_display;
          return {};
        },
        sub {
          $self->parse_locals;
          return {};
        },
        sub {
          $self->parse_radix;
          return {};
        },
        'parse_macro_section',
        'parse_stack_assignment',
        sub {
          $self->commit;
          $self->fail('Illegal instruction');
        },
      );
    },
  ) or return {};

  # convert the array_ref to a hash_ref
  my $ref = { };
  foreach ( @$result ) {
    next unless %$_;
    my ($key, $value) = each %$_;
    $ref->{$key} = $value;
  }

  # create new entry
  return {
    name        => $ident,
    type        => $type,
    assignments => $ref,
  };
}

sub parse_stack_assignment {    # \%assignment ()
  my $self = shift;
  my $type = 'register';

  # REGX|REGY|REGZ|REGT ..
  my $ident = $self->token_kw_icase( @register );
  $self->commit;

  # retrieve the state immediately after the commit
  my ($line) = $self->where;

  # REGX SET ..
  $self->expect( qr/SET(?=[ \t])/i );
  $self->commit;

  # REGX SET number
  my $value = $self->maybe('token_number')
    or $self->fail( "Need expression" );
  $self->commit;

  # skip whitespace and ensure no extra characters remain on the line
  $self->skip_ws;
  my ($next_line) = $self->where;
  $line != $next_line
    or $self->fail( "Extra characters" );

  # create new entry
  $ident = $self->_canonical_symbol($ident);
  return {
    $ident => {
      type  => $type,
      value => $value,
    }
  };
}

sub parse_data_block {    # \%block (|$ident)
  my $self  = shift;
  my $ident = shift || '_DATA';
  my $type  = 'data';

  # insert symbol into global symbol table
  $ident = $self->_canonical_symbol($ident);
  $self->{symbols}{$ident} = $type;

  # call each data line
  my $result = $self->sequence_of(
    sub {
      $self->commit;

      $self->any_of(
        sub {
          $self->parse_display;
          return {};
        },
        sub {
          $self->parse_locals;
          return {};
        },
        sub {
          $self->parse_radix;
          return {};
        },
        'parse_macro_section',
        'parse_data_definition',
        sub {
          $self->commit;
          $self->fail('Illegal instruction');
        },
      );
    },
  ) or return {};

  # create new entry
  return {
    name        => $ident,
    type        => $type,
    definitions => [ grep { %$_ } @$result ],
  };
}

sub parse_data_definition {    # \%definition ()
  my $self = shift;
  my $type = 'equation';

  # line tracking for listing
  $self->skip_ws;
  my ($line) = $self->where;
  my $source_id = $self->{_track_source_ids} ? $line : undef;

  my $ident = $self->token_ident;
  my $fail_pos = $self->pos - length $ident;

  # test if symbol already exists
  $ident = $self->_canonical_symbol($ident);
  if (exists $self->{symbols}{$ident}) {
    $self->fail_from(
      $fail_pos,
      $self->{symbols}{$ident} eq $type
        ? 'Symbol already defined'
        : 'Symbol already different kind'
    );
  }
  $self->commit;

  $self->expect(qr/EQU(?=[ \t])/i);
  $self->commit;

  my $is_string = 0;
  my $value = $self->any_of(
    'token_number',
    sub {
      my $value = $self->maybe('token_string');
      length $value
        or $self->fail('Need quoted string');
      $is_string = 1;
      return $value;
    },
    sub {
      $self->commit;
      $self->fail('Need expression');
    },
  );

  if ( $is_string ) {
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
        $state =~ /normal/ and do {
          if (/\\/) {
            $state = 'start';
            $char = '\\';
          }
          else {
            exists $character->{$char}
              or
            $self->fail_from( $fail_pos - length($char), "Unknown character" );
            $char = '';
          }
          last;
        };
        $state =~ /start/ and do {
          if (/\\/) {
            $state = 'normal';
            exists $character->{$char}
              or
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
        $state =~ /middle/ and do {
          if (/\d/) {
            $state = 'end';
          }
          else {
            $state = 'unknown';
          }
          last;
        };
        $state =~ /end/ and do {
          if (/\\/) {
            $state = 'unknown';
          }
          else {
            $state = 'normal';
            exists $character->{$char}
              or
            $self->fail_from( $fail_pos - length($char), 
              "Unknown character sequence" );
            $char = '';
          }
          last;
        };
        DEFAULT: {
          $self->fail_from( $fail_pos - length($char), 
            "Invalid character sequence" );
        }
      }
      $fail_pos++;
    }
    $state =~ /normal/ or
      $self->fail_from( $fail_pos - length($char) - 1, "Argument mismatch" );
  }
  $self->commit;

  # skip whitespace and ensure no extra characters remain on the line
  $self->skip_ws;
  my ($next_line) = $self->where;
  $line != $next_line
    or $self->fail( "Extra characters" );

  # insert symbol into global symbol table
  $self->{symbols}{$ident} = $type;

  # create new entry
  my $entry = {
    name  => $ident,
    type  => $type,
    value => $value,
  };

  # line tracking for listing
  $entry->{_source_id} = $source_id
    if defined $source_id;

  return $entry;
}

sub parse_code_block {    # \%block (|$ident)
  my $self  = shift;
  my $ident = shift || '_TEXT';
  my $type  = 'code';

  # retrieve the current local symbols before parsing
  my $locals = $self->{locals};

  # insert symbol into global symbol table
  $ident = $self->_canonical_symbol($ident);
  $self->{symbols}{$ident} = $type;

  # call each code line
  my $result = $self->sequence_of(
    sub {
      $self->commit;

      $self->any_of(
        sub {
          $self->parse_display;
          return {};
        },
        'parse_locals',
        sub {
          $self->parse_radix;
          return {};
        },
        'parse_label',
        'parse_macro_section',
        'parse_macro_statement',
        'parse_code_instruction',
        'parse_code_literal',
        sub {
          $self->commit;
          $self->fail('Illegal instruction');
        },
      );
    },
  ) or return {};

  # create new entry
  return {
    name        => $ident,
    type        => $type,
    statements  => [
      # Insert the saved locals state before the actual statements
      {
        directive => {
          type  => 'locals',
          value => $locals,
        },
      },
      grep { %$_ } @$result
    ],
  };
}

sub parse_code_instruction {    # \%instruction ()
  my $self = shift;

  my $mnemonic = $self->token_kw_operation(
    @instructions,
    @with_address,
    @with_variables,
    @with_digits,
    @with_indirects,
    @expressions,
    @functions,
    @register,
  );
  $self->commit;

  # retrieve the state immediately after the commit
  my $pos = $self->pos;
  my ($line) = $self->where;
  my $source_id = $self->{_track_source_ids} ? $line : undef;

  my $statement;
  my $operand;
  my $kind = instruction_kind($mnemonic);
  SWTICH: for ( $kind ) {
    /plain/ and do {
      # instructions without an operand
      $statement = {
        instruction => {
          value => $mnemonic,
        },
      };
      last;
    };

    /address/ and do {
      # instructions with an address: GTO and XEQ
      $operand = $self->maybe( 'token_label' )
        or $self->fail( "Illegal origin address" );
      $statement = {
        instruction => {
          value => $mnemonic,
        },
      };
      if ($operand =~ /^[A-Z]\d{3}$/) {
        $statement->{instruction}{operand} = {
          type  => 'address',
          value => $operand,
        },
      }
      else {
        my $flags = $self->_find_macro_symbol($operand);
        my $type = $flags & MACRO_LOCAL ? 'local'
                 : $flags & MACRO_DUMMY ? 'dummy'
                 :                        'label';
        $statement->{instruction}{operand} = {
          type  => $type,
          value => $self->_canonical_symbol($operand),
        };
      };
      last;
    };

    /variable/ and do {
      # instructions with a variable: LBL and INPUT
      my $dummy = $self->maybe('parse_macro_dummy');
      if (defined $dummy) {
        $statement = {
          instruction => {
            value => $mnemonic,
            operand => {
              type  => 'dummy',
              value => $dummy->{dummy}{name},
            },
          },
        };
      }
      else {
        $operand = $self->generic_token( variable => qr/[A-Z](?=[\s;]|\z)/ );
        $statement = {
          instruction => {
            value => $mnemonic,
            operand  => {
              type  => 'variable',
              value => $operand,
            },
          },
        };
      }
      last;
    };

    /digit/ and do {
      # instructions with a number 0 < n < 11: CF, FIX, ...
      $operand = $self->maybe('token_int');
      defined $operand
        or $self->fail( "Illegal number" );
      $operand =~ /^\d+$/ && $operand <= 11 or
        $self->fail( "Expected number from 0 to 11" );
      $statement = {
        instruction => {
          value => $mnemonic,
          operand  => {
            type  => 'decimal',
            value => $operand,
          },
        },
      };
      last;
    };

    /indirect/ and do {
      # instructions with a direct or indirect variable: STO, RCL, VIEW, ...
      my $dummy = $self->maybe('parse_macro_dummy');
      if (defined $dummy) {
        $operand = {
          type  => 'dummy',
          value => $dummy->{dummy}{name},
        };
      }
      else {
        my $value = $self->generic_token(
          variable => qr/(?:[A-Z]|\([IJ]\))(?=[\s;]|\z)/
        );
        $operand = {
          type  => 'variable',
          value => $value,
        };
      }
      $statement = {
        instruction => {
          value   => $mnemonic,
          operand => $operand,
        },
      };
      last;
    };

    /expression/ and do {
      # instructions with an expression: EQN
      $statement = {
        instruction => {
          value => $mnemonic,
        },
      };

      # determine all current equations
      my @equations = grep {
        $self->{symbols}{$_} eq 'equation'
      } keys %{ $self->{symbols} };

      # test if it is an equation
      $operand = $self->maybe( sub { $self->token_kw_icase(@equations) } );
      my $type = defined $operand ? 'equation' : 'expression';
      if ( $type eq 'equation' ) {
        # it is a symbol created via EQU
        $operand = $self->_canonical_symbol($operand);
      }
      else {
        # it must be a quoted expression
        $operand = $self->generic_token( expression
          => qr/\'(.*?)\'/, sub { $1 } );
      }
      $statement->{instruction}{operand} = {
        type  => $type,
        value => $operand,
      };
      last;
    };

    DEFAULT: {
      my ($next_line) = $self->where;
      $line == $next_line 
        or $self->fail_from( $pos, "Argument mismatch" );
    }
  }

  # skip whitespace and ensure no extra characters remain on the line
  $self->skip_ws;
  my ($next_line) = $self->where;
  $line != $next_line
    or $self->fail( "Extra characters" );    # .. on line

  # line tracking for listing
  $statement->{_source_id} = $source_id
    if $self->{_track_source_ids} && defined $source_id;

  return $statement;
}

sub parse_code_literal {    # \%literal ()
  my $self = shift;

  # line tracking for listing
  $self->skip_ws;
  my ($line) = $self->where;
  my $source_id = $self->{_track_source_ids} ? $line : undef;

  my $literal = $self->any_of(
    sub { { literal => { kind => 'constant',
      value => $self->token_kw_operation( @constants ) } } },
    sub { { literal => { kind => 'vector',  value => $self->token_vector  } } },
    sub { { literal => { kind => 'complex', value => $self->token_complex } } },
    sub { { literal => { kind => 'binary',  value => $self->token_binary  } } },
    sub { { literal => { kind => 'octal',   value => $self->token_octal   } } },
    sub { { literal => { kind => 'decimal', value => $self->token_decimal } } },
    sub { { literal => { kind => 'hex',     value => $self->token_hex     } } },
    sub { { literal => { kind => 'decimal', value => $self->token_float   } } },
    sub {
      my $base = $self->{radix};
      if ( $base == 2 ) {
        my $value = $self->generic_token(binary => qr/[01]+/ );
        return { literal => { kind => 'binary', value => $value . 'b' } };
      }
      elsif ( $base == 8 ) {
        my $value = $self->generic_token(octal => qr/[0-7]+/ );
        return { literal => { kind => 'octal', value => $value . 'o' } };
      }
      elsif ( $base == 16 ) {
        my $value = $self->generic_token(hex => qr/[\dA-F]+/ );
        return { literal => { kind => 'hex', value => $value . 'h' } };
      }
      return { literal => { kind => 'decimal', value => $self->token_int } };
    },
  );
  $self->commit;

  # skip whitespace and ensure no extra characters remain on the line
  $self->skip_ws;
  my ($next_line) = $self->where;
  $line != $next_line
    or $self->fail( "Extra characters" );    # .. on line

  # line tracking for listing
  $literal->{_source_id} = $source_id
    if $self->{_track_source_ids} && defined $source_id;

  return $literal;
}

sub parse_label {    # \%label ()
  my $self = shift;

  # LABEL:
  $self->skip_ws;
  my $fail_pos = $self->pos;
  my $ident = $self->maybe( sub {
    my $re = $self->pattern_label;
    $self->generic_token( label => qr/($re):/i, sub { $1 } );
  } ) or $self->fail("Illegal segment address");

  # check if symbol starts with number
  $ident !~ /^\d/
    or $self->fail( "Labels can't start with numeric characters" );

  # check if symbol looks like an address
  $ident !~ /^[A-Z]\d{3}$/ 
    or $self->fail( "Illegal segment address");
  $self->commit;

  my $name = $self->_canonical_symbol($ident);

  # Determine macro-specific label type.
  my $flags = $self->_find_macro_symbol($ident);
  my $type = $flags & MACRO_LOCAL ? 'local'
           : $flags & MACRO_DUMMY ? 'dummy'
           :                        'label';

  if ($type eq 'label') {
    # check if symbol already exists
    if ( exists $self->{symbols}{$name} ) {
      $self->fail_from(
        $fail_pos, 
        $self->{symbols}{$name} eq $type
          ? "Symbol already defined"
          : "Symbol already different kind"
      )
    }

    # insert symbol into global symbol table
    $self->{symbols}{$name} = $type 
      if $self->{locals} && $name !~ /^@@/;
  }

  my $entry = { 
    label => { 
      type => $type,
      name => $name,
    },
  };

  my ($line) = $self->where;
  my $source_id = $self->{_track_source_ids} ? $line : undef;
  $entry->{_source_id} = $source_id if defined $source_id;

  return $entry;
}

sub parse_local {     # \%local ()
  my $self = shift;
  my $type = 'local';

  # LOCAL ..
  $self->maybe_expect(qr/LOCAL(?=[\s;])/i)
    or $self->fail("Expected LOCAL");
  $self->commit;

  # LOCAL label ..
  my $ident = $self->on_parse_line('token_label')
    or $self->fail("Illegal local argument");

  # check if symbol starts with number
  $ident !~ /^\d/
    or $self->fail( "Illegal local argument" );

  my @locals;
  while (1) {
    my $fail_pos = $self->pos - length $ident;
    my $local = $self->_canonical_symbol($ident);

    # check if the local name collides with an existing symbol
    if (exists $self->{symbols}{$local}) {
      $self->fail_from(
        $fail_pos,
        $self->{symbols}{$local} eq $type
          ? 'Symbol already defined'
          : 'Symbol already different kind'
      );
    }
    push @locals, $local;

    last unless $self->maybe_expect(',');
    $self->commit;

    $ident = $self->on_parse_line( 'token_label' )
      or $self->fail("Illegal local argument");
  }

  return {
    locals => \@locals,
  };
}

sub parse_macro_section {    # \%section ()
  my $self = shift;
  my $type = 'macro';

  # MACRO name arguments
  my $header = $self->parse_macro_header;
  my ($name) = keys %$header;

  $self->{_macro}{$name} = $header->{$name};

  # establish current macro context
  local $self->{_macro_name} = $name;

  # content between MACRO header and ENDM
  my $block = $self->scope_of(
    undef,
    sub { $self->parse_macro_block() },
    qr/ENDM\b/i,
  );

  # extend macro entry with parsed block content
  my $macro = $self->{_macro}{$name};

  $macro->{locals} = $block->{locals}
    if $block->{locals} && @{$block->{locals}};

  $macro->{statements} = $block->{statements}
    if $block->{statements} && @{$block->{statements}};

  # register the successfully parsed macro definition
  $self->{symbols}{$name} = $type;

  return {
    macro => {
      $name => $macro,
    },
  };
}

sub parse_macro_header {    # \%header ()
  my $self = shift;
  my $type = 'macro';

  # MACRO ..
  $self->maybe_expect( qr/MACRO(?=[\s;]|\z)/i )
    or $self->fail("Expected MACRO");
  $self->commit;

  # retrieve the line after the commit
  my ($line) = $self->where;

  # MACRO name ..
  my $name = $self->on_parse_line( 'token_ident' )
    or $self->fail("Missing macro ID");
  my $fail_pos = $self->pos - length $name;

  # check if the macro name is a reserved word
  $name = $self->_canonical_symbol($name);
  if (exists $self->{symbols}{$name}) {
    $self->fail_from(
      $fail_pos,
      $self->{symbols}{$name} eq $type
        ? 'Symbol already defined'
        : 'Symbol already different kind'
    );
  }
  $self->commit;

  # parse macro arguments if present
  my %seen;
  my @arguments;
  my $ident = $self->on_parse_line( 'token_ident' );
  if (defined $ident) {
    while (1) {
      my $argument = $self->_canonical_symbol($ident);

      !$seen{$argument}++
        or $self->fail("Duplicate dummy argument: $ident");

      push @arguments, $argument;

      last unless $self->maybe_expect(',');
      $self->commit;

      $ident = $self->on_parse_line( 'token_ident' )
        or $self->fail("Illegal macro argument");
    }
  }

  # skip whitespace and ensure no extra characters remain on the line
  $self->skip_ws;
  my ($next_line) = $self->where;
  $line != $next_line
    or $self->fail( "Extra characters" );

  # create new entry
  return {
    $name => {
      arguments => \@arguments,
    }
  };
}

sub parse_macro_block {   # $entry ()
  my $self = shift;

  my $macro_name = $self->{_macro_name};
  my $macro = $self->{_macro}{$macro_name};

  # parse LOCAL declarations before any macro statements
  my $locals = $self->sequence_of( 'parse_local' ) || [];

  # flatten the array of local declarations into a simple list of local names
  my @locals = map { @{$_->{locals}} } @$locals;
  $macro->{locals} = \@locals if @locals;

  # call each code line
  my $result = $self->sequence_of(
    sub {
      $self->commit;

      $self->any_of(
        sub {
          $self->parse_display;
          return {};
        },
        'parse_locals',
        sub {
          $self->parse_radix;
          return {};
        },
        'parse_label',
        'parse_code_instruction',
        'parse_code_literal',
        'parse_macro_dummy',
        sub {
          $self->commit;
          $self->fail('Illegal instruction');
        },
      );
    },
  ) or return {};

  my $entry = {
    statements => $result,
  };
  $entry->{locals} = \@locals if @locals;
  return $entry;
}

sub parse_macro_dummy {    # $entry ()
  my $self = shift;

  my $macro_name = $self->{_macro_name}
    or return;

  my $macro = $self->{_macro}{$macro_name}
    or return;

  my $ident = $self->token_kw_icase(@{$macro->{arguments}})
    or return;

  return {
    dummy => {
      name => $self->_canonical_symbol($ident),
    },
  };
}

sub parse_macro_statement {
  my $self = shift;

  # parse macro name
  my @macros = grep { $self->{symbols}{$_} eq 'macro' } 
    keys %{$self->{symbols}};

  my $ident = $self->token_kw_icase(@macros)
    or return;    # return if there exists no macro names
  $self->commit;

  my $name = $self->_canonical_symbol($ident);
  my $macro = $self->{_macro}{$name};

  # actual arguments
  my @arguments;
  my $argument = $self->on_parse_line('token_ident');
  if (defined $argument) {
    while (1) {
      push @arguments, $argument;

      last unless $self->maybe_expect(',');
      $self->commit;

      $argument = $self->on_parse_line('token_ident')
        or $self->fail("Illegal macro argument");
    }
  }

  @arguments == @{$macro->{arguments}}
    or $self->fail("Wrong number of macro arguments");

  return {
    macro => {
      name      => $name,
      arguments => \@arguments,
    },
  };
}

sub parse_end {    # $start_addr|undef ()
  my $self = shift;

  # error, if at the end of input
  $self->at_eos and
    $self->fail( "Unexpected end of file (no END directive)" );
  
  # error, if statements appear outside a declared segment
  $self->maybe_expect( qr/END\b/i )
    or $self->fail( "Code or data emission to undeclared segment" );
  
  # get the start address if present
  my $start_addr = $self->maybe(
    sub {
      my $ident = $self->token_label();
      my $name = $self->_canonical_symbol($ident);
      exists $self->{symbols}{$name} && $self->{symbols}{$name} eq 'label' 
        or $self->fail( "Expected label" );
      return $name;
    },
  );

  # ignore any data after END
  $self->substring_before( qr/$/s );
  
  return undef unless $start_addr;
  return { type => 'label', value => $start_addr };
}

# token methods

sub token_binary {    # $binary ()
  my $self = shift;
  return $self->generic_token( binary => $self->{patterns}{binary} );
}

sub token_complex {    # $complex ()
  my $self = shift;
  return $self->generic_token( complex => $self->{patterns}{complex} );
}

sub token_decimal {    # $decimal ()
  my $self = shift;
  return $self->generic_token( decimal => $self->{patterns}{decimal} );
}

sub token_hex {    # $hex ()
  my $self = shift;
  return $self->generic_token( hex => $self->{patterns}{hex} );
}

sub token_octal {    # $octal ()
  my $self = shift;
  return $self->generic_token( octal => $self->{patterns}{octal} );
}

sub token_kw_icase {    # $keyword ()
  my $self = shift;
  my @acceptable = @_;

  $self->skip_ws;

  my $pos = pos $self->{str};

  defined( my $kw = $self->token_ident )
    or return undef;

  grep { /^$kw$/i } @acceptable
    or pos($self->{str}) = $pos, $self->fail( "Expected any of " 
      . join( ", ", @acceptable ) );

  return $kw;
}

sub token_kw_operation {    # $keyword ()
  my $self = shift;
  my @acceptable = @_;

  $self->skip_ws;

  my $pos = pos $self->{str};
  
  defined( my $kw = $self->generic_token( 
    operation => $self->{patterns}{operation}, ) 
  ) or return undef;

  my @expected = @acceptable[ 0 .. ($#acceptable < 4 ? $#acceptable : 4) ];
  my $expected = join( ", ", @expected );
  $expected .= ", ... (" . @acceptable . " total)" if @acceptable > 5;

  grep { $_ eq $kw } @acceptable
    or pos($self->{str}) = $pos, $self->fail( "Expected any of $expected" );

  return $kw;
}

sub token_vector {    # $vector ()
  my $self = shift;
  my $vector = $self->generic_token( vector => $self->{patterns}{vector} );
  return $vector;
}

sub token_label {    # $label ()
  my $self = shift;
  my $label = $self->generic_token( label => $self->{patterns}{label} );
  return $label;
}

sub on_parse_line {
  my ($self, $parser) = @_;

  my ($line) = $self->where;

  return $self->maybe(
    sub {
      my $result = ref $parser eq 'CODE'
        ? $parser->()
        : $self->$parser();

      my ($next_line) = $self->where;

      $line == $next_line
        or $self->fail('left current line');

      return $result;
    }
  );
}

# -------------------------------------------------------------------------
# Private Methods
# -------------------------------------------------------------------------

sub _canonical_symbol {    # $symbol ($name)
  my ($self, $name) = @_;
  return uc $name;
}

sub _find_before {    # $pos ($substr)
  my $self    = shift;
  my $substr  = reverse shift;

  exists $self->{reverse_str}
    or $self->{reverse_str} = reverse $self->{str};
  
  exists $self->{length}
    or $self->{length} = length $self->{str};

  my $pos = $self->{length} - $self->pos;
  my $idx = index $self->{reverse_str}, $substr, $pos;

  return $idx > 0
    ? $self->{length} - $idx - length $substr
    : $self->pos;
}

sub _find_macro_symbol {    # $flags ($ident)
  my ($self, $ident) = @_;

  my $macro_name = $self->{_macro_name}
    or return MACRO_NONE;

  my $macro = $self->{_macro}{$macro_name}
    or return MACRO_NONE;

  my $name = $self->_canonical_symbol($ident);
  my $flags = MACRO_NONE;

  $flags |= MACRO_LOCAL
    if grep { $_ eq $name } @{$macro->{locals} || []};

  $flags |= MACRO_DUMMY
    if grep { $_ eq $name } @{$macro->{arguments} || []};

  return $flags;
}

sub _fixup_labels {   # $ast ($ast)
  my ($self, $ast) = @_;

  my ($code) = grep { $_->{type} eq 'code' } @{$ast->{segments}};
  return $ast unless $code;

  my $locals;
  my $scope  = 0;
  my $next   = 0;
  my %labels;
  my @statements;

  for my $statement (@{$code->{statements}}) {

    # LOCALS / NOLOCALS
    if (
      $statement->{directive}
      && $statement->{directive}{type} eq 'locals'
    ) {
      $locals = $statement->{directive}{value};
      next;
    }

    defined $locals
      or $self->warn("Missing initial LOCALS state");

    # Label declaration
    if (my $label = $statement->{label}) {
      if ($label->{type} eq 'label') {
        my $name = $label->{name};

        if ($locals && $name =~ /^@@/) {
          $labels{$scope}{$name} //= sprintf '@@%04d', ++$next;
          $label->{name} = $labels{$scope}{$name};
        }
        elsif ($name !~ /^@@/) {
          ++$scope;
        }

        delete $label->{type};
      }
    }

    # Label reference
    if (my $instruction = $statement->{instruction}) {
      my $operand = $instruction->{operand};

      if ($operand && $operand->{type} eq 'label') {
        my $name = $operand->{value};

        if ($locals && $name =~ /^@@/) {
          $labels{$scope}{$name} //= sprintf '@@%04d', ++$next;
          $operand->{value} = $labels{$scope}{$name};
        }
      }
    }

    push @statements, $statement;
  }

  $code->{statements} = \@statements;

  return $ast;
}

sub _prepare_ast {    # $ast ($ast)
  my ($self, $ast) = @_;

  my %content_key = (
    data  => 'definitions',
    code  => 'statements',
    stack => 'assignments',
  );

  my @segments;
  my %section_by_type;

  for my $segment ( grep { %$_ } @{$ast->{segments}} ) {
    my $type     = $segment->{type};
    my $key      = $content_key{$type};
    my $existing = $section_by_type{$type};

    if ( defined $key && $existing ) {
      if ( ref $segment->{$key} eq 'HASH' ) {
        @{$existing->{$key}}{ keys %{$segment->{$key}} }
          = values %{$segment->{$key}};
      }
      else {
        push @{$existing->{$key}}, @{$segment->{$key}};
      }
      next;
    }

    push @segments, $segment;
    $section_by_type{$type} = $segment if defined $key;
  }

  my $header = delete $ast->{header};

  $ast->{segments} = \@segments;
  @$ast{keys %$header} = values %$header;
  $ast->{language} //= $self->{language};
  $ast->{model}    //= $self->{model};

  return $self->_fixup_labels($ast);
}

1;
