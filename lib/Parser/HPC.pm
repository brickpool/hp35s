package Parser::HPC;
# ABSTRACT: Simple recursive-descent 1-pass assembler parser for HP calculators

# ------------------------------------------------------------------------
# Boilerplate
# ------------------------------------------------------------------------

use strict;
use warnings;

use version;
our $VERSION = version->declare('v0.5.1');

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

  # A symbol represents a value, which can be a variable, address label, 
  # or an operand to an assembly instruction and directive
  # store predefined symbols
  my %constants   = map { $_ => 'constant'  } @constants;
  my %variables   = map { $_ => 'variable'  } 'A'..'Z',
                                              @register;
  my %directives  = map { $_ => 'directive' } @directives,
                                              @languages,
                                              @segments;
  my %opcodes     = map { $_ => 'opcode'    } @instructions,
                                              @with_address,
                                              @with_digits,
                                              @with_variables,
                                              @with_indirects,
                                              @expressions,
                                              @functions;
  my %equations  = map { $_ => 'equation'   } @predefined;
  $self->{_symbols} = { %constants, %variables, %directives, %opcodes, 
    %equations };

  # Default numeric radix is decimal
  $self->{_radix} = 10;

  # Local label handling
  $self->{_locals} = 1;
  $self->{_local_scope} = '';

  return $self;
}

# -------------------------------------------------------------------------
# Overload existing Methods
# -------------------------------------------------------------------------

sub from_string {    # $result ($str)
  my ($self, $source) = @_;
  my $macro_parser = Parser::HPC::Macro->new(
    patterns => { ident => $self->{patterns}->{ident} },
  );
  $source = $macro_parser->from_string($source);
  return $self->SUPER::from_string($source);
}

sub parse {    # $tree ()
  my $self = shift;

  # %TITLE directive
  my $title = $self->maybe(
    sub { $self->parse_title }
  );

  my $mode     = $self->parse_mode;
  my $language = $self->parse_language;
  my $model    = $self->parse_model;

  # list of segments
  $self->{_assignments} = {};
  my $result = $self->sequence_of(
    sub {
      return { } if defined $self->parse_locals;
      return { } if defined $self->parse_radix;
      return { } if defined $self->parse_display;
      $self->parse_segment;
    },
  ) or $self->fail( "Expecting SEGMENT keyword" );

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

  # end directive
  my $start = $self->parse_end;
  
  my $root = {
    language  => $language,
    model     => $model,
    segments  => \@segments,
  };
  if ( keys %{ $self->{_assignments} } ) {
    push @segments, {
      name        => 'STACK',
      type        => 'stack',
      assignments => $self->{_assignments},
    };
  }
  $root->{title}     = $title if $title;
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
      my $base = $self->{_radix};
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

sub parse_title {    # $title ()
  my $self = shift;

  # %TITLE "title"
  $self->expect( qr/\%TITLE(?=[ \t])/i );
  $self->commit;

  # retrieve the state immediately after the commit
  my ($line, $col, $line_text) = $self->where;
  my $pos = $self->pos;

  # get quoted string (internally skips whitespace)
  my $result = eval { $self->token_string };

  # check if quoted string is present
  if (!defined $result) {
    my $fail_pos = $pos + 1;
    $self->fail_from( $fail_pos, "Need quoted string" );
  }

  # check whether we have left the line
  my ($line_after) = $self->where;
  if ( $line != $line_after ) {
    my $fail_pos = $pos + length($line_text) - $col;
    $self->fail_from( $fail_pos, "Missing end quote" );
  }

  # skip and throw an error if we're still on the same line
  $self->skip_ws;
  my ($next_line) = $self->where;
  $line != $next_line
    or $self->fail( "Extra characters" );    # .. on line

  return $result;
}

sub parse_display {    # $message ()
  my $self = shift;

  # DISPLAY "message"
  defined $self->maybe_expect( qr/DISPLAY(?=[ \t])/i )
    or return;
  $self->commit;

  # retrieve the state immediately after the commit
  my ($line, $col, $line_text) = $self->where;
  my $pos = $self->pos;

  # get quoted string (internally skips whitespace)
  my $result = eval { $self->token_string };

  # check if quoted string is present
  if (!defined $result) {
    my $fail_pos = $pos + 1;
    $self->fail_from( $fail_pos, "Need quoted string" );
  }

  # check whether we have left the line
  my ($line_after) = $self->where;
  if ( $line != $line_after ) {
    my $fail_pos = $pos + length($line_text) - $col;
    $self->fail_from( $fail_pos, "Missing end quote" );
  }

  # skip and throw an error if we're still on the same line
  $self->skip_ws;
  my ($next_line) = $self->where;
  $line != $next_line
    or $self->fail( "Extra characters" );    # .. on line

  $self->warn($result);

  return $result;
}

sub parse_mode {   # $bool ()
  my $self = shift;

  $self->maybe_expect( qr/IDEAL(?=[\s;])/ )
    or $self->fail("IDEAL must be specified first");
  my ($line) = $self->where;
  $self->skip_ws;
  my ($next_line) = $self->where;
  $line != $next_line
    or $self->fail("Extra characters");

  return 1;
}

sub parse_language {    # $language ()
  my $self = shift;

  my $result = eval { $self->token_kw( @languages ) };
  defined $result
    or $self->fail("Missing or illegal language ID");
  my ($line) = $self->where;
  $self->skip_ws;
  my ($next_line) = $self->where;
  $line != $next_line
    or $self->fail("Extra characters");

  return $result;
}

# Model returns an integer indicating the current model: 
# 0 = TINY 
# 1 = SMALL 
# 2 = COMPACT 
# 3 = MEDIUM 
# 4 = LARGE 
# 5 = HUGE 
sub parse_model {    # $model ()
  my $self = shift;

  $self->maybe_expect( qr/MODEL(?=[ \t])/ )
    or $self->fail("MODEL must follow language ID");
  my ($line) = $self->where;

  my $result = $self->maybe_expect( qr/TINY(?=[\s;])/ );
  my ($model_line) = $self->where;
  defined $result && $line == $model_line
    or $self->fail("Missing or illegal model ID");

  $self->skip_ws;
  my ($next_line) = $self->where;
  $line != $next_line
    or $self->fail("Extra characters");

  return 0;
}

sub parse_radix {    # $base ()
  my $self = shift;

  # RADIX ..
  defined $self->maybe_expect( qr/RADIX(?=[ \t])/i )
    or return;

  # retrieve the state immediately after the commit
  $self->commit;
  my ($line) = $self->where;

  # RADIX base
  my $result = eval {
    $self->generic_token( radix => qr/(?:2|8|10|16)(?=[\s;])/ )
  };
  defined $result
    or $self->fail("Illegal radix");

  # skip and throw an error if we're still on the same line
  $self->skip_ws;
  my ($next_line) = $self->where;
  $line != $next_line
    or $self->fail( "Extra characters" );    # .. on line

  $self->{_radix} = 0+ $result;
  return $self->{_radix};
}

sub parse_locals {    # $bool ()
  my $self = shift;

  my $result = $self->maybe_expect(qr/(?:NOLOCALS|LOCALS)(?=[\s;])/i);
  defined $result
    or return;
  $self->commit;
  my ($line) = $self->where;

  # skip and throw an error if we're still on the same line
  $self->skip_ws;
  my ($next_line) = $self->where;
  $line != $next_line
    or $self->fail( "Extra characters" );    # .. on line

  $self->{_locals} = $result eq 'LOCALS' ? 1 : 0;
  return $self->{_locals};
}

sub parse_segment {    # $segment ()
  my $self = shift;

  my $result;

  # DATASEG or CODESEG or STACK
  my $segment = $self->token_kw_icase( @segments );
  $self->commit;

  my $ends = qr/(?=(?:DATASEG|CODESEG|STACK|END)\b)/i;
  SWITCH: for ($segment) {
    /^DATASEG$/i and do {
      $result = $self->scope_of(
        undef, 
        sub { $self->parse_data_block }, 
        $ends
      );
      last;
    };
    /^CODESEG$/i and do {
      $result = $self->scope_of(
        undef, 
        sub { $self->parse_code_block }, 
        $ends
      );
      last;
    };
    /^STACK$/i and do {
      $result = $self->scope_of(
        undef, 
        sub { $self->parse_stack_block }, 
        $ends
      );
      last;
    };
    DEFAULT: {
      $self->fail("Bad keyword In SEGMENT statement");
    };
  }

  return $result;
}

sub parse_data_block {    # $block (|$ident)
  my $self  = shift;
  my $ident = shift || '_DATA';
  my $type  = 'data';
  
  $ident = uc $ident;
  my $result = $self->sequence_of(
    sub {
      $self->commit;
      $self->parse_data_statement;
    },
  ) or return undef;

  # create new entry
  my $entry = {
    name        => $ident,
    type        => $type,
    definitions => [ grep { %$_ } @$result ],
  };

  # insert symbol into global symbol table
  $self->{_symbols}->{$ident} = $type;

  return $entry;
}

sub parse_data_statement {    # $statement ()
  my $self = shift;
  my $type = 'equation';

  return { } if defined $self->parse_locals;
  return { } if defined $self->parse_radix;

  my $ident = $self->token_ident;
  my $fail_pos = $self->pos - length $ident;

  # check if a new segment is defined or end has been reached
  if ( $ident =~ /^(?:DATASEG|CODESEG|STACK|END)$/i ) {
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

  defined $self->maybe_expect( qr/EQU(?=[ \t])/i )
    or $self->fail( "Expecting segment or group quantity" );

  my $is_string = 0;
  my $value;
  $value = $self->any_of(
    sub { $self->token_number },
    sub {
      my $value = $self->token_string;
      $is_string = 1;
      return $value;
    },
    sub { 0 },
  ) or $self->fail( "Need expression" );

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

  # create new entry
  my $entry = {
    name  => $ident,
    type  => $type,
    value => $value,
  };

  # insert symbol into global symbol table
  $self->{_symbols}->{$ident} = $type;

  return $entry;
}

sub parse_code_block {    # $block (|$ident)
  my $self  = shift;
  my $ident = shift || '_TEXT';
  my $type  = 'code';

  $ident = uc $ident;
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
  ) or return undef;
  
  my @statements;
  for (my $i = 0; $i < @$result; $i++ ) {
    push @statements, @{ $tags[$i] };
    if ( exists $result->[$i]->{display} 
      || exists $result->[$i]->{radix}
      || exists $result->[$i]->{locals}
    ) {
      next;
    }

    push @statements, $result->[$i];
  }

  # create new entry
  my $entry = {
    name        => $ident,
    type        => $type,
    statements  => \@statements,
  };
  
  # insert symbol into global symbol table
  $self->{_symbols}->{$ident} = $type;

  return $entry;
}

sub parse_code_statement {    # $statement ()
  my $self = shift;

  $self->skip_ws;
  my ($line) = $self->where;

  my $locals = $self->parse_locals;
  return { locals => $locals } if defined $locals;

  my $radix = $self->parse_radix;
  return { radix => $radix } if defined $radix;

  my $display = $self->parse_display;
  return { display => $display } if defined $display;

  my $statement = $self->any_of(
    sub { $self->parse_code_instruction },
    sub { $self->parse_code_literal },
    sub { undef },
  );
  defined $statement
    or $self->fail( "Illegal instruction" );
  $self->commit;

  # skip and throw an error if we're still on the same line
  $self->skip_ws;
  my ($next_line) = $self->where;
  $line != $next_line
    or $self->fail( "Extra characters" );    # .. on line

  return $statement;
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

  # get current position in str for "fail_from"
  my $pos = $self->pos;
  my ($line) = $self->where;
  $self->commit;

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
      eval { $operand = $self->generic_token(label
        => qr/(?:\?\?\d{4}|\@{0,2}\w+)/, sub { $_[1] } )
      } or
        $self->fail( "Illegal origin address" );
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
      } else {
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
      my $number = eval { $self->token_int };
      defined $number or
        $self->fail( "Illegal number" );
      $operand = $number;
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
      my @equations = ();
      foreach ( keys %{ $self->{_symbols} } ) {
        push @equations, $_ if $self->{_symbols}->{$_} eq 'equation';
      }
      # test if it is an equation
      if ( eval { $operand = $self->token_kw(@equations) } ) {
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
      @_ = $self->where;
      $line eq $_[0] or
        $self->fail_from( $pos, "Argument mismatch" );
    }
  }

  return $statement;
}

sub parse_code_literal {    # $literal ()
  my $self = shift;

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
      my $base = $self->{_radix};
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

  $self->{_local_scope} = $ident if $nonlocal;

  return { label => { name => $ident } };
}

sub parse_stack_block {    # $block (|$ident)
  my $self  = shift;
  my $ident = shift || 'STACK';
  my $type  = 'stack';

  my $result = $self->sequence_of(
    sub {
      $self->commit;
      $self->parse_stack_statement;
    },
  ) or return undef;

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

  # insert symbol into global symbol table
  $self->{_symbols}->{$ident} = $type;

  return $entry;
}

sub parse_stack_statement {    # $statement ()
  my $self = shift;
  my $type = 'register';

  return { } if defined $self->parse_locals;
  return { } if defined $self->parse_radix;

  my $ident = $self->token_kw( @register );
  $self->commit;

  defined $self->maybe_expect( qr/SET(?=[ \t])/i )
    or $self->fail( "Expecting segment or group quantity" );

  my $value;
  eval { $value = $self->token_number };
  defined $value
    or $self->fail( "Need expression" );

  my ($line) = $self->where;
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
      defined $self->{_symbols}->{$name} 
        && $self->{_symbols}->{$name} eq 'label' 
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
  return $self->{_locals} && $ident =~ /^@@/
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

__END__

=pod

=head1 NAME

Parser::HPC - parse HP calculator assembler source code

=head1 SYNOPSIS

  use Parser::HPC;

  my $parser = Parser::HPC->new;

  my $program = $parser->from_string(<<'ASM');
  %TITLE "Example"
    IDEAL
    P35S
    MODEL TINY
    STACK
      REGX SET 4

  DATASEG
    FORMULA EQU 'A+B'

  CODESEG
  start:
    LBL A
    0
    EQN FORMULA
    GTO start
    RTN

  END start
  ASM

=head1 DESCRIPTION

C<Parser::HPC> is a recursive-descent parser for HP calculator assembler source
code.

The parser converts its input into an abstract syntax tree represented by Perl
hashes, arrays, and scalar values. The root node describes the calculator
language, memory model, optional program metadata, and the stack, data, and
code sections found in the source.

After an optional C<%TITLE> directive, the source must contain C<IDEAL>,
C<P35S>, and C<MODEL TINY>, in that order and on separate lines. These header
keywords are case-sensitive. Only C<IDEAL> mode, the C<P35S> language, and the
C<TINY> memory model are supported.

The assembler uses TASM-inspired simplified section directives. C<STACK>,
C<DATASEG>, and C<CODESEG> select the meaning of the statements that follow;
they do not represent separate HP-35s address spaces. A new section directive
implicitly ends the preceding section.

C<SET> assignments are accepted only in C<STACK>, C<EQU> definitions only in
C<DATASEG>, and executable calculator statements only in C<CODESEG>. Explicit
C<SEGMENT> and C<ENDS> syntax is not supported.

Source passed to L</from_string> is first processed by L<Parser::HPC::Macro>.
The resulting source is then passed to the L<Parser::MGC> parser interface.

This document describes the parser interface and the AST nodes returned by its
parsing methods. The complete assembler syntax is documented in the project
wiki.

=head1 ABSTRACT SYNTAX TREE

=head2 AST construction flow

The normal entry point expands macros in L</from_string> and then parses the
source with L</parse>. The parser methods are composed as follows:

  source code
    |
    v
  from_string()
    |
    v
  parse()
    +-- parse_title()                   # optional
    +-- parse_mode()
    +-- parse_language()
    +-- parse_model()
    +-- parse_segment()                 # repeated section selectors
    |     |
    |     +-- parse_data_block()
    |     |      '-- parse_data_statement()
    |     |
    |     +-- parse_code_block()
    |     |      +-- parse_label()      # zero or more per line
    |     |      '-- parse_code_statement()
    |     |              +-- parse_code_instruction()
    |     |              '-- parse_code_literal()
    |     |
    |     '-- parse_stack_block()
    |            '-- parse_stack_statement()
    |
    '-- parse_end()

L</parse_segment> handles the C<STACK>, C<DATASEG>, and C<CODESEG> section
directives and dispatches to the corresponding block parser. Each section
continues until another section directive or C<END> is encountered.

The block parsers restrict statements according to their section. C<STACK>
accepts register C<SET> assignments, C<DATASEG> accepts C<EQU> definitions,
and C<CODESEG> accepts labels, calculator instructions, and literals.
C<RADIX> and local-label directives are handled where supported by the
corresponding block parser.

Each block parser collects the results of its statement parser. Data
definitions and code statements retain source order, while stack assignments
are stored by register name. Repeated sections of the same type are combined
in the program AST.

In code sections, labels are collected before each statement and inserted
immediately before it in the C<statements> array. Parser directives handled
within a code section may affect parser state or produce temporary results but
are not retained in the final C<statements> array.

L</parse_end> supplies the optional C<startaddr> field, while L</parse_title>,
L</parse_language>, and L</parse_model> supply program metadata.
L</parse_mode> validates the required syntax mode but does not add a field to
the AST.

The parser methods build nodes using token methods, which match source items
and return scalar values rather than AST nodes. Some token methods used by this
parser, including C<token_ident>, C<token_float>, C<token_int>, and C<token_kw>,
are inherited from L<Parser::MGC>.

=head2 Program node

L</parse> returns the root of the abstract syntax tree:

  {
    language => $language,
    model    => $model,
    segments => [
      $segment,
      ...
    ],

    # Present only when specified by the source
    title => $title,

    # Present only when END specifies a start label
    startaddr => {
      type  => 'label',
      value => $label,
    },
  }

C<language> contains the calculator language identifier, currently C<P35S>.

C<model> contains the numeric memory-model identifier parsed from the C<MODEL>
directive. The only supported model is C<TINY>, represented by the integer 
value C<0>.

C<title> is present when the source contains a valid C<%TITLE> directive.

C<startaddr> is present only when the C<END> directive specifies a previously
defined label. Its C<value> contains the upper-case, qualified label name.

C<segments> is an array reference containing the parsed stack, data, and code
sections. The field name C<segments> is retained for AST compatibility. The
source-language directives C<STACK>, C<DATASEG>, and C<CODESEG> select parsing
contexts and do not imply separate HP-35s address spaces.

Repeated sections of the same type are combined into a single corresponding AST 
node. Data definitions and code statements retain source order, while stack 
assignments are stored by register name.

A stack segment node is present only when the parsed source contains stack
assignments. C<STACK> itself does not allocate a fixed-size stack; it selects
the context in which C<SET> assignments are parsed.

Directives processed between sections do not produce segment nodes.

=head2 Data segment node

A data segment node has the form:

  {
    name        => $name,
    type        => 'data',
    definitions => [
      $definition,
      ...
    ],
  }

C<name> is the internal identifier C<_DATA>. Explicit segment names are not
supported.

C<definitions> contains C<EQU> definition nodes in source order. C<EQU>
definitions are accepted only while C<DATASEG> is active.

A definition node has the form:

  {
    name  => $name,
    type  => 'equation',
    value => $value,
  }

Definition names retain the spelling returned by the identifier tokenizer.
C<value> contains either a parsed numeric value or the contents of a quoted
string.

C<EQU> definitions represent data used by the target program. Although
C<DATASEG> selects a distinct parsing context, it does not create a separate
HP-35s address space.

Parser directives that do not define a symbol are omitted from
C<definitions>.

=head2 Code segment node

A code segment node has the form:

  {
    name       => $name,
    type       => 'code',
    statements => [
      $statement,
      ...
    ],
  }

C<name> is the internal identifier C<_TEXT>. Explicit segment names are not
supported.

C<statements> contains label, instruction, and literal nodes in source order.
Executable calculator statements are accepted only while C<CODESEG> is active.

Labels do not consume calculator program lines. Consecutive label nodes
therefore refer to the following instruction or literal.

Parser directives handled inside C<CODESEG> may affect parser state but are not
included in the final C<statements> array.

=head3 Label node

A label declaration produces:

  {
    label => {
      name => $name,
    },
  }

Label names are converted to upper case.

When local labels are enabled, a local label name is qualified with its active
non-local scope. For example, C<@@LOOP> in the scope C<START> becomes
C<START:@@LOOP>. A local label before the first non-local label uses an empty
scope and is returned as C<:@@LOOP>.

=head3 Instruction node

An instruction without an operand produces:

  {
    instruction => {
      value => $mnemonic,
    },
  }

An instruction with an operand produces:

  {
    instruction => {
      value   => $mnemonic,
      operand => {
        type  => $type,
        value => $value,
      },
    },
  }

The C<value> field of the instruction contains the parsed mnemonic.

The operand C<type> may be one of the following:

=over 4

=item C<address>

A calculator address such as C<A001>.

=item C<label>

A global or qualified local label name.

=item C<variable>

A direct or indirect calculator variable.

=item C<decimal>

A decimal integer operand used by an instruction that accepts a numeric
argument.

=item C<equation>

The name of a previously defined equation.

=item C<expression>

The contents of an inline quoted expression.

=back

The operand field is omitted for instructions that do not accept an operand.

=head3 Literal node

A calculator literal produces:

  {
    literal => {
      kind  => $kind,
      value => $value,
    },
  }

C<kind> may be one of the following:

=over 4

=item C<constant>

A predefined calculator constant.

=item C<vector>

A vector literal.

=item C<complex>

A complex-number literal.

=item C<binary>

A binary numeric literal.

=item C<octal>

An octal numeric literal.

=item C<decimal>

An integer or floating-point decimal literal.

=item C<hex>

A hexadecimal numeric literal.

=back

The representation of C<value> depends on the tokenizer that recognized the
literal. Consumers must not assume that every numeric value is represented by
the same Perl scalar form. For example, decimal integer values may be numeric
scalars while decimal floating-point values may retain their textual
representation.

Unsuffixed non-decimal code literals receive a suffix in the returned value so
that the selected radix remains available to the AST consumer.

=head2 Stack segment node

A stack segment node has the form:

  {
    name        => $name,
    type        => 'stack',
    assignments => {
      $register => {
        type  => 'register',
        value => $value,
      },
      ...
    },
  }

C<name> is the internal identifier C<STACK>. Explicit segment names are not
supported.

C<STACK> selects the section in which register C<SET> assignments are
accepted. It does not take a size argument and does not allocate a fixed-size
stack.

C<assignments> is a hash reference keyed by register name. Each entry contains
the value assigned to that register by C<SET>.

Unlike data definitions and code statements, stack assignments do not retain
source order. If a register occurs more than once, the later C<SET> assignment
replaces the earlier entry in the returned hash.

C<SET> assignments are accepted only while C<STACK> is active. Their numeric
values are interpreted using the active radix.

Parser directives that do not assign a register are omitted from
C<assignments>.

=head2 AST consumer notes

The AST represents parsed source structure rather than the calculator's final
program or memory layout.

The C<segments> array contains nodes produced from C<STACK>, C<DATASEG>, and
C<CODESEG> sections. These nodes represent source organization and must not be
interpreted as separate HP-35s address spaces.

The AST does not contain a derived label index or calculated program
addresses. Labels remain individual nodes in the C<statements> array. Address
calculation and label indexing are the responsibility of the AST consumer.

Consumers should inspect the discriminating keys and fields rather than
relying on Perl scalar representation alone:

=over 4

=item *

A segment node is identified by its C<type> field: C<stack>, C<data>, or
C<code>.

=item *

A code statement is identified by the presence of C<label>, C<instruction>, or
C<literal>.

=item *

An instruction operand is identified by its C<type> field.

=item *

A literal is identified by its C<kind> field.

=item *

Numeric C<value> fields may be returned as numeric or textual Perl scalars,
depending on the token form.

=back

=head1 CONSTRUCTOR

=head2 new

  my $parser = Parser::HPC->new(%args);

Creates a new HP calculator assembler parser.

Additional arguments are passed to the constructor inherited from
L<Parser::MGC>. The token patterns required by the HP calculator assembler are
installed by this constructor.

The initial numeric radix is decimal. Local-label processing is initially
enabled and the initial local-label scope is empty.

=head1 METHODS

=head2 from_string

  my $tree = $parser->from_string($source);

Processes C<$source> with L<Parser::HPC::Macro> and then parses the result 
using the C<from_string> interface inherited from L<Parser::MGC>.

Returns the complete program AST documented under L</ABSTRACT SYNTAX TREE>.

Parsing failures are reported through the L<Parser::MGC> parser interface.

=head2 parse

  my $tree = $self->parse();

Parses a complete program and returns the program node documented under
L</Program node>.

The method parses, in order, an optional title, the required C<IDEAL>, C<P35S>,
and C<MODEL TINY> header lines, the program sections, and the terminating
C<END> directive.

C<STACK>, C<DATASEG>, and C<CODESEG> select the parser context for the
statements that follow. Repeated sections of the same type are combined into
the corresponding node in the C<segments> array.

Directives between sections may affect parser state but do not create entries
in the returned C<segments> array.

=head2 parse_code_block

  my $block = $self->parse_code_block();
  my $block = $self->parse_code_block($name);

Parses the statements in the current C<CODESEG> section and returns a code
segment node as documented under L</Code segment node>.

If C<$name> is omitted or false, the internal node name is C<_TEXT>.

Label nodes are inserted into C<statements> immediately before the code
statement to which they apply. Parser directives handled within the code
section may affect parser state or produce temporary nodes; these nodes are
discarded and are not included in the final C<statements> array.

=head2 parse_code_instruction

  my $instruction = $self->parse_code_instruction();

Parses one calculator instruction and returns an instruction node as
documented under L</Instruction node>.

Depending on the instruction kind, the result may contain no operand or an 
operand of type C<address>, C<label>, C<variable>, C<decimal>, C<equation>, 
or C<expression>.

Label operand values are converted to upper case and are qualified when 
local-label processing applies.

=head2 parse_code_literal

  my $literal = $self->parse_code_literal();

Parses one calculator literal and returns a literal node as documented under 
L</Literal node>. A parse failure is reported if the input does not contain a 
recognized literal in the current parser context.

The returned node is suitable for inclusion in the C<statements> array of a
code segment.

=head2 parse_code_statement

  my $statement = $self->parse_code_statement();

Parses one statement from the current C<CODESEG> section.

For a calculator instruction, returns the node documented under
L</parse_code_instruction>. For a literal, returns the node documented under
L</parse_code_literal>.

The following directives are also accepted within C<CODESEG> and temporarily
produce these nodes:

  { locals  => $boolean }

  { radix   => $base }

  { display => $message }

These directive nodes may affect parser state or produce diagnostic output.
They are consumed by L</parse_code_block> and are not included in the final
C<statements> array.

C<EQU> definitions and C<SET> assignments are not accepted in C<CODESEG>.
They belong to C<DATASEG> and C<STACK>, respectively.

=head2 parse_data_block

  my $block = $self->parse_data_block();
  my $block = $self->parse_data_block($name);

Parses the definitions in the current C<DATASEG> section and returns a data
segment node as documented under L</Data segment node>.

If C<$name> is omitted or false, the internal node name is C<_DATA>.

C<EQU> definitions are returned in source order. Parser directives handled
within the data section may affect parser state or produce empty nodes; these
nodes are omitted from the final C<definitions> array.

=head2 parse_data_statement

  my $definition = $self->parse_data_statement();

Parses one statement from the current C<DATASEG> section.

An C<EQU> definition returns:

  {
    name  => $name,
    type  => 'equation',
    value => $value,
  }

C<value> contains either the parsed numeric value or the contents of a quoted
string.

C<EQU> definitions are accepted only within C<DATASEG>. C<SET> assignments are
not accepted in this section and belong to C<STACK>.

C<RADIX>, C<LOCALS>, and C<NOLOCALS> directives may affect parser state and
return an empty hash reference. Empty nodes are removed by L</parse_data_block> 
and do not appear in the final C<definitions> array.

=head2 parse_display

  my $message = $self->parse_display();

Parses a C<DISPLAY> directive.

Returns the contents of the directive's quoted string and writes the same 
message, followed by a newline, to standard error.

Returns C<undef> if the next input item is not a C<DISPLAY> directive.

The return value may be used temporarily by L</parse_code_statement>, but it 
does not become part of the final program AST.

=head2 parse_end

  my $startaddr = $self->parse_end();

Parses the terminating C<END> directive.

If the directive specifies a previously defined label, returns:

  {
    type  => 'label',
    value => $name,
  }

The returned label is upper case and is qualified when local-label processing 
applies.

Returns C<undef> if the directive does not specify a start label.

Input remaining after the C<END> directive is ignored.

=head2 parse_mode

  my $bool = $self->parse_mode();

Parses the required C<IDEAL> directive and returns true for success.

IDEAL is the only supported syntax mode. The directive must occupy its own
line, apart from whitespace and a comment. Its return value represents parser
state and is not stored directly in the program AST.

=head2 parse_label

  my $label = $self->parse_label();

Parses a label declaration and returns:

  {
    label => {
      name => $name,
    },
  }

The label name is converted to upper case. Active local labels are returned 
using their qualified names.

The returned node is suitable for inclusion in the C<statements> array of a
code segment.

=head2 parse_language

  my $language = $self->parse_language();

Parses the required calculator language identifier following C<IDEAL>.
Currently, only C<P35S> is accepted. The identifier must occupy its own line, 
apart from whitespace and a comment.

The returned identifier is stored in the C<language> field of the program node.

=head2 parse_locals

  my $enabled = $self->parse_locals();

Parses a C<LOCALS> or C<NOLOCALS> directive and updates the parser's
local-label state.

Returns C<1> for C<LOCALS>, C<0> for C<NOLOCALS>, and C<undef> if the next 
input item is neither directive.

The return value represents parser state and is not stored directly in the 
final AST.

=head2 parse_model

  my $model = $self->parse_model();

Parses the required C<MODEL TINY> directive following the language identifier 
and returns the integer C<0> for the TINY memory model. No other memory model 
is currently supported.

The keyword and its argument must occur on the same line, with no additional 
content apart from whitespace and a comment.

The model value is stored in the C<model> field of the program node.

=head2 parse_radix

  my $base = $self->parse_radix();

Parses a numeric-radix directive and updates the active radix.

Returns C<2>, C<8>, C<10>, or C<16>. Returns C<undef> if the next input item is 
not a radix directive.

The return value represents parser state and is not stored directly in the 
final AST.

=head2 parse_segment

  my $segment = $self->parse_segment();

Parses one of the C<STACK>, C<DATASEG>, or C<CODESEG> section directives and
dispatches to the corresponding block parser.

Each directive selects the parsing context for the statements that follow.
The selected section continues until another C<STACK>, C<DATASEG>, or
C<CODESEG> directive, or the terminating C<END> directive, is encountered.

C<STACK> selects C<SET> assignments, C<DATASEG> selects C<EQU> definitions,
and C<CODESEG> selects executable calculator statements.

Explicit C<SEGMENT> and C<ENDS> syntax is not supported.

=head2 parse_stack_block

  my $block = $self->parse_stack_block();

Parses the assignments in the current C<STACK> section and returns a stack
segment node as documented under L</Stack segment node>.

C<STACK> is a section selector and does not take a size argument. Register
C<SET> assignments are accepted only while this section is active.

Assignments are stored by register name rather than in source order. If the
same register is assigned more than once, the later C<SET> assignment replaces
the earlier value.

C<RADIX>, C<LOCALS>, and C<NOLOCALS> directives may affect parser state and do
not produce entries in the final C<assignments> hash.

=head2 parse_stack_statement

  my $statement = $self->parse_stack_statement();

Parses one statement from the current C<STACK> section.

A register C<SET> assignment returns:

  {
    $register => {
      type  => 'register',
      value => $value,
    },
  }

The register must be one of the registers accepted by the target vocabulary.
C<value> is parsed using the active numeric radix.

C<SET> assignments are accepted only within C<STACK>. Repeated assignments to
the same register are permitted; when the stack block is assembled into its
AST node, the later assignment replaces the earlier value.

C<RADIX>, C<LOCALS>, and C<NOLOCALS> directives may affect parser state and
return an empty hash reference.

=head2 parse_title

  my $title = $self->parse_title();

Parses a C<%TITLE> directive and returns the contents of its quoted string.

The return value is stored in the optional C<title> field of the program node.

The token methods return matched scalar values. Unlike the C<parse_*> methods, 
they do not return AST nodes.

=head1 TOKEN PARSING METHODS

The token methods return matched scalar values. Unlike the C<parse_*> methods, 
they do not return AST nodes.

=head2 token_binary

  my $binary = $self->token_binary();

Returns a binary literal matched using the parser's binary token pattern.

=head2 token_complex

  my $complex = $self->token_complex();

Returns a complex-number literal matched using the parser's complex token 
pattern.

=head2 token_decimal

  my $decimal = $self->token_decimal();

Returns a suffixed decimal literal matched using the parser's decimal token 
pattern.

=head2 token_hex

  my $hex = $self->token_hex();

Returns a hexadecimal literal matched using the parser's hexadecimal token 
pattern.

=head2 token_kw_icase

  my $keyword = $self->token_kw_icase(@acceptable);

Matches an identifier against C<@acceptable> without regard to case and returns 
the spelling found in the source.

Reports a parse failure if an identifier is present but does not match an 
acceptable value.

=head2 token_kw_operation

  my $keyword = $self->token_kw_operation(@acceptable);

Matches an operation token against C<@acceptable> and returns the matched 
operation.

Operation matching is case-sensitive.

=head2 token_number

  my $value = $self->token_number();

Parses a numeric value.

Explicitly suffixed binary, octal, decimal, and hexadecimal values are
recognized independently of the active radix.

For an unsuffixed value, interpretation depends on the active radix. Unsuffixed 
binary, octal, and hexadecimal integer values are converted to signed 36-bit 
numeric values. Under decimal radix, numeric parsing is delegated to the parent 
parser.

=head2 token_octal

  my $octal = $self->token_octal();

Returns an octal literal matched using the parser's octal token pattern.

=head2 token_string

  my $string = $self->token_string();

Parses a delimited string and returns its contents without the surrounding 
delimiters.

Backslash escape sequences remain part of the returned string.

=head2 token_vector

  my $vector = $self->token_vector();

Returns a vector literal matched using the parser's vector token pattern.

=head1 SEE ALSO

L<Parser::MGC>, L<Parser::HPC::Macro>, L<HP35s::Vocabulary>,
C<bin/asm2hpc.pl>

The assembler language is documented in the project wiki:

L<Directives|https://github.com/brickpool/hp35s/wiki/Directives>

L<Symbols|https://github.com/brickpool/hp35s/wiki/Symbols>

=head1 AUTHOR

J. Schneider <brickpool@cpan.org>

=cut
