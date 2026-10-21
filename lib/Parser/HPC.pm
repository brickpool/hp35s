package Parser::HPC;
# ABSTRACT: Simple recursive-descent 1-pass assembler parser for HP calculators

# ------------------------------------------------------------------------
# Boilerplate
# ------------------------------------------------------------------------

use strict;
use warnings;

use version;
our $VERSION = version->declare('v0.5.2');

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
use constant pattern_comment   => qr/;.*\n/;
use constant pattern_operation => qr/[^\s\(\)]+/;
use constant pattern_ident     => qr/[[:alpha:]\@_\$?][[:alnum:]\@_\$?]{0,246}/;

# new numeric patterns
use constant pattern_vector  => qr/\[[\-\d\.e]+,[\-\d\.e]+(?:,[\-\d\.e]+)?\]/;
use constant pattern_binary  => qr/[01]+b/;
use constant pattern_octal   => qr/[0-7]+o/;
use constant pattern_hex     => qr/[\dA-F]+h/;
use constant pattern_complex => qr/[\-\d\.e]+[it][\-\d\.e]+/;
use constant pattern_decimal => qr/-?\d+d\b/;
use constant pattern_float   => qr/-?(?:\d*\.\d+|\d+\.)(?:e-?\d+)?|-?\d+e-?\d+/;

# -------------------------------------------------------------------------
# Constructor
# -------------------------------------------------------------------------

sub new {    # $parser (%args)
  my $class = shift;
  
  # Call the constructor of the parent class
  my $self = $class->SUPER::new( 
    patterns => {
      comment    => pattern_comment,
      ident      => pattern_ident,
      operations => pattern_operation,
      vector     => pattern_vector,
      binary     => pattern_binary,
      octal      => pattern_octal,
      hex        => pattern_hex,
      complex    => pattern_complex,
      decimal    => pattern_decimal,
      float      => pattern_float,
    },
    @_,
  );

  # public parser attributes
  $self->{mode}     = 'IDEAL';   # IDEAL mode by default
  $self->{model}    = 0;         # TINY model by default
  $self->{title}    = undef;     # title is undef by default
  $self->{radix}    = 10;        # radix is decimal by default
  $self->{locals}   = 1;         # local label handling enabled by default
  $self->{language} = 'P35S';    # language is P35S by default

  # private parser attributes
  $self->{_local_scope} = '';   # Local label handling

  # A symbol represents a value, which can be a variable, address label, 
  # or an operand to an assembly instruction and directive
  # store predefined symbols
  my %constants   = map { $_ => 'constant'  } @constants;
  my %variables   = map { $_ => 'variable'  } 'A'..'Z',
                                              @register;
  my %directives  = map { $_ => 'directive' } @directives,
                                              @languages,
                                              @segments,
                                              @listings,
                                              @modes,
                                              @models;
  my %opcodes     = map { $_ => 'opcode'    } @instructions,
                                              @with_address,
                                              @with_digits,
                                              @with_variables,
                                              @with_indirects,
                                              @expressions,
                                              @functions;
  my %equations  = map { $_ => 'equation'   } @predefined;
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
    patterns => { ident => $self->{patterns}->{ident} },
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
  
  my @segments;
  my %content_key = (
    data  => 'definitions',
    code  => 'statements',
    stack => 'assignments',
  );
  my %section_by_type;
  for my $segment ( grep { %$_ } @$result ) {
    my $type     = $segment->{type};
    my $key      = $content_key{$type};
    my $existing = $section_by_type{$type};

    if ( defined $key && $existing ) {
      if ( ref $segment->{$key} eq 'HASH' ) {
        @{$existing->{$key}}{ keys %{ $segment->{$key} } }
          = values %{ $segment->{$key} };
      }
      else {
        push @{ $existing->{$key} }, @{ $segment->{$key} };
      }
      next;
    } 

    push @segments, $segment;
    $section_by_type{$type} = $segment if defined $key;
  }

  my $root = { %$header };
  delete $root->{display};
  $root->{segments}  = \@segments;
  $root->{language} ||= $self->{language};
  $root->{model}    ||= $self->{model};
  $root->{startaddr} = $start if $start;
  return $root;
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

sub parse_header {
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
            'parse_display',
            'parse_language',
            'parse_model',
            'parse_locals',
            'parse_radix',
            sub {
              $self->commit;
              $self->fail('Illegal instruction');
            },
          );
        },
      );
    },
    qr/(?=(?:$sections)\b)/i,
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

sub parse_title {    # $title ()
  my $self = shift;

  # %TITLE "title"
  $self->expect( qr/\%TITLE(?=\s)/i );
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
  return { title => $self->{title} };
}

sub parse_display {    # $message ()
  my $self = shift;

  # DISPLAY "message"
  $self->expect( qr/DISPLAY(?=\s)/i );
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

  return { display => $display };
}

sub parse_mode {   # $bool ()
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

  $self->{mode} = uc($mode);
  return { mode => $self->{mode} };
}

sub parse_language {    # $language ()
  my $self = shift;

  my $language = $self->maybe( sub { $self->token_kw_icase( @languages ) } );
  $self->fail("Missing or illegal language ID") unless $language;
  $self->commit;

  # retrieve the state immediately after the commit
  my ($line) = $self->where;

  # skip whitespace and ensure no extra characters remain on the line
  $self->skip_ws;
  my ($next_line) = $self->where;
  $line != $next_line
    or $self->fail("Extra characters");

  $self->{language} = $language;
  return { language => $self->{language} };
}

sub parse_model {    # $model ()
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
  $self->{model} = $models{uc $model};
  return { model => $self->{model} };
}

sub parse_radix {    # $base ()
  my $self = shift;

  # RADIX ..
  $self->expect( qr/RADIX(?=[ \t])/i );
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
  return { radix => $self->{radix} };
}

sub parse_locals {    # $bool ()
  my $self = shift;

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

  $self->{locals} = $result eq 'LOCALS' ? 1 : 0;
  return { locals => $self->{locals} };
}

sub parse_segment {    # $segment ()
  my $self = shift;

  # DATASEG or CODESEG or ..
  my $segment = $self->token_kw_icase( @segments );
  $self->commit;

  my $sections = join '|' => ( @segments, 'END' );
  return $self->scope_of(
    undef, 
    sub { 
      SWITCH: for (uc $segment) {
        /DATASEG/ and return $self->parse_data_block; 
        /CODESEG/ and return $self->parse_code_block;
        /STACK/   and return $self->parse_stack_block;
      }
    },
    qr/(?=(?:$sections)\b)/i
  );
}

sub parse_stack_block {    # $block (|$ident)
  my $self  = shift;
  my $ident = uc( shift || 'STACK' );
  my $type  = 'stack';

  # insert symbol into global symbol table
  $self->{symbols}->{$ident} = $type;

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
  my $entry = {
    name        => $ident,
    type        => $type,
    assignments => $ref,
  };

  return $entry;
}

sub parse_stack_assignment {    # $assignment ()
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
  my $entry = {
    $ident => {
      type  => $type,
      value => $value,
    }
  };

  return $entry;
}

sub parse_data_block {    # $block (|$ident)
  my $self  = shift;
  my $ident = uc( shift || '_DATA' );
  my $type  = 'data';

  # insert symbol into global symbol table
  $self->{symbols}->{$ident} = $type;

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
        'parse_data_definition',
        sub {
          $self->commit;
          $self->fail('Illegal instruction');
        },
      );
    },
  ) or return {};

  # create new entry
  my $entry = {
    name        => $ident,
    type        => $type,
    definitions => [ grep { %$_ } @$result ],
  };

  return $entry;
}

sub parse_data_definition {    # $definition ()
  my $self = shift;
  my $type = 'equation';

  # line tracking for listing
  $self->skip_ws;
  my ($line) = $self->where;
  my $source_id = $self->{_track_source_ids} ? $line : undef;

  my $ident = $self->token_ident;
  my $fail_pos = $self->pos - length $ident;

  # test if symbol already exists
  if (exists $self->{symbols}->{$ident}) {
    $self->fail_from(
      $fail_pos,
      $self->{symbols}->{$ident} eq $type
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
  $self->{symbols}->{$ident} = $type;

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

sub parse_code_block {    # $block (|$ident)
  my $self  = shift;
  my $ident = uc( shift || '_TEXT' );
  my $type  = 'code';

  # insert symbol into global symbol table
  $self->{symbols}->{$ident} = $type;

  # call each code line
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
        'parse_label',
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
  my $entry = {
    name        => $ident,
    type        => $type,
    statements  => [ grep { %$_ } @$result ],
  };
  
  return $entry;
}

sub parse_code_instruction {    # $instruction ()
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
      $operand = $self->maybe( sub { 
        $self->generic_token(
          label => qr/(?:\?\?\d{4}|\@{0,2}\w+)/, sub { $_[1] }
        ) 
      } ) 
        or $self->fail( "Illegal origin address" );
      $statement = {
        instruction => {
          value => $mnemonic,
        },
      };
      if ($operand =~ /^[A-Z]\d{3}$/) {
        $statement->{instruction}->{operand} = {
          type  => 'address',
          value => $operand,
        },
      } 
      else {
        $statement->{instruction}->{operand} = {
          type  => 'label',
          value => $self->_qualify_label_name($operand),
        };
      };
      last;
    };
    /variable/ and do {
      # instructions with a variable: LBL and INPUT
      $operand = $self->generic_token( variable => qr/[A-Z]/ );
      $statement = {
        instruction => {
          value => $mnemonic,
          operand  => {
            type  => 'variable',
            value => $operand,
          },
        },
      };
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
      # instructions with a (indirect) variable: VIEW, ...
      $operand = $self->generic_token( variable => qr/[A-Z]|(?:\([IJ]\))/ );
      $statement = {
        instruction => {
          value => $mnemonic,
          operand  => {
            type  => 'variable',
            value => $operand,
          },
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
        $self->{symbols}->{$_} eq 'equation'
      } keys %{ $self->{symbols} };

      # test if it is an equation
      $operand = $self->maybe( sub { $self->token_kw_icase(@equations) } );
      if ( defined $operand ) {
        $statement->{instruction}->{operand} = {
          type  => 'equation',
          value => $operand,
        };
      }
      else {
        # it must be an quoted expression
        $operand = $self->generic_token( expression
          => qr/\'(.*?)\'/, sub { $1 } );
        $statement->{instruction}->{operand} = {
          type  => 'expression',
          value => $operand,
        };
      }
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

sub parse_code_literal {    # $literal ()
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

sub parse_label {    # $label ()
  my $self = shift;
  my $type = 'label';
  my $ident;

  $ident = $self->expect( qr/(?:\?\?\d{4}|\@{0,2}\w+):/ );
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
  my $nonlocal = $ident !~ /^@@/;
  $ident = $self->_qualify_label_name($ident);

  # check if symbol already exists
  if ( defined $self->{symbols}->{$ident} ) {
    $self->fail_from(
      $fail_pos,
      $self->{symbols}->{$ident} eq $type
        ?
      "Symbol already defined"
        :
      "Symbol already different kind"
    )
  }

  # insert symbol into global symbol table
  $self->{symbols}->{$ident} = $type;

  $self->{_local_scope} = $ident if $nonlocal;

  my $declaration = { label => { name => $ident } };
  my ($line) = $self->where;
  my $source_id = $self->{_track_source_ids} ? $line : undef;
  $declaration->{_source_id} = $source_id if defined $source_id;
  return $declaration;
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
  my $start_addr = $self->any_of(
    sub {
      my $ident = $self->generic_token( label => qr/\@{0,2}\w+/ );
      my $name = $self->_qualify_label_name($ident);
      defined $self->{symbols}->{$name} 
        && $self->{symbols}->{$name} eq 'label' 
          or $self->fail( "Expected label" );
      return $name;
    },
    sub { 0 },
  );

  # ignore any data after END
  $self->substring_before( qr/$/s );
  
  return undef unless $start_addr;
  return { type => 'label', value => uc $start_addr };
}

# token methods

sub token_binary {    # $binary ()
  my $self = shift;
  return $self->generic_token(binary => pattern_binary);
}

sub token_complex {    # $complex ()
  my $self = shift;
  return $self->generic_token(complex => pattern_complex);
}

sub token_decimal {    # $decimal ()
  my $self = shift;
  return $self->generic_token(decimal => pattern_decimal);
}

sub token_hex {    # $hex ()
  my $self = shift;
  return $self->generic_token(hex => pattern_hex);
}

sub token_octal {    # $octal ()
  my $self = shift;
  return $self->generic_token(octal => pattern_octal);
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
  
  defined( my $kw = $self->generic_token( operation => pattern_operation, ) )
    or return undef;

  grep { $_ eq $kw } @acceptable
    or pos($self->{str}) = $pos, $self->fail( "Expected any of "
      . join( ", ", @acceptable ) );

  return $kw;
}

sub token_vector {    # $vector ()
  my $self = shift;
  my $vector = $self->generic_token( vector => pattern_vector );
  return $vector;
}

# -------------------------------------------------------------------------
# Private Methods
# -------------------------------------------------------------------------

sub _qualify_label_name {    # $qualified_ident ($ident)
  my ($self, $ident) = @_;
  $ident = uc $ident;
  return $self->{locals} && $ident =~ /^@@/
    ? $self->{_local_scope} . ':' . $ident : $ident;
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

  return
    $idx > 0
      ?
    $self->{length} - $idx - length $substr
      :
    $self->pos;
}

1;
