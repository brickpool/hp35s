package Parser::HPC;
# ABSTRACT: Simple recursive-descent 1-pass assembler parser for HP calculators

use strict;
use warnings;

our $VERSION = 'v0.5.0';

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

use parent 'Parser::MGC';

use constant pattern_comment    => qr/;.*\n/;
use constant pattern_operation  => qr/[^\s\(\)]+/;
use constant pattern_ident      => qr/[[:alpha:]@_\$?][[:alnum:]@_\$?]{0,246}/;

my @directives = (
  'DISPLAY', 'ENDS', 'END', 'EQU', 'LOCALS', 'NOLOCALS', 'MODEL', 'RADIX', 
  'SEGMENT', 'SET', '%TITLE',
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
  $self->{_symbols} = { %constants, %variables, %directives, %opcodes, 
    %equations };

  # Labels allow you to name the positions of specific instructions
  $self->{_labels} = undef;

  return $self;
}

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
    /DATA/i and do {
      $result = $self->scope_of(
        undef,
        sub { $self->parse_data_block( $name ) },
        qr/ENDS/i
      );
      last;
    };
    /CODE/i and do {
      $result = $self->scope_of(
        undef,
        sub { $self->parse_code_block( $name ) },
        qr/ENDS/i
      );
      last;
    };
    /STACK/i and do {
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
      $state =~ /normal/ and do {
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
      $state =~ /start/ and do {
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
          exists $character->{$char} or
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

  $self->skip_ws;
  my ($line) = $self->where;

  my $statement = $self->any_of(
    sub { $self->parse_code_instruction },
    sub { $self->parse_code_literal },
    sub { undef },
  );
  defined $statement
    or
  $self->fail( "Illegal instruction" );

  $self->commit;
  $self->skip_ws;
  @_ = $self->where;
  $line ne $_[0] or
    $self->fail("Extra characters on line");

  return $statement;
}

sub parse_code_instruction {
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
        => qr/\@{0,2}\w+/, sub { $_[1] } )
      } or
        $self->fail( "Illegal origin address" );

      $statement = {
        instruction => {
          value => $mnemonic,
        },
      };
      if ($operand =~ /[A-Z]\d{3}/) {
        $statement->{instruction}->{operand} = {
          type  => 'address',
          value => $operand,
        },
      } else {
        $statement->{instruction}->{operand} = {
          type  => 'label',
          value => uc $operand,
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
      $operand = $self->generic_token( number => qr/10|11|[0-9]/ );
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

sub parse_code_literal {
  my $self = shift;

  my $literal = $self->any_of(
    sub { [ constant => $self->token_kw_operation( @constants ) ] },
    sub { [ vector => $self->generic_token(vector
      => qr/\[[\-\d\.e]+,[\-\d\.e]+(?:,[\-\d\.e]+)?\]/, sub { $_[1] } ) ] },
    sub { [ binary => $self->generic_token(binary
      => qr/[01]+b/, sub { $_[1] } ) ] },
    sub { [ octal => $self->generic_token(octal
      => qr/[0-7]+o/, sub { $_[1] } ) ] },
    sub { [ hex => $self->generic_token(hex
      => qr/[\dA-F]+h/, sub { $_[1] } ) ] },
    sub { [ complex => $self->generic_token(complex
      => qr/[\-\d\.e]+[it][\-\d\.e]+/, sub { $_[1] } ) ] },
    sub { [ decimal => $self->generic_token(number
      => qr/[\-\d\.e]+d?/, sub { $_[1] } ) ] },
  );
  $self->commit;

  my ($kind, $value) = @$literal;
  return {
    literal => {
      kind  => $kind,
      value => $value,
    },
  };
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

sub parse_stack_block {
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

sub parse_stack_statement {
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

sub parse_end {
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

sub token_kw_icase {
  my $self = shift;
  my @acceptable = @_;

  $self->skip_ws;

  my $pos = pos $self->{str};

  defined( my $kw = $self->token_ident )
    or
  return undef;

  grep { /^$kw$/i } @acceptable
    or
  pos($self->{str}) = $pos, $self->fail( "Expected any of " 
    . join( ", ", @acceptable ) );

  return $kw;
}

sub token_kw_operation {
  my $self = shift;
  my @acceptable = @_;

  $self->skip_ws;

  my $pos = pos $self->{str};
  
  defined( my $kw = $self->generic_token( operation => pattern_operation, ) )
    or
  return undef;

  grep { $_ eq $kw } @acceptable
    or
  pos($self->{str}) = $pos, $self->fail( "Expected any of "
    . join( ", ", @acceptable ) );

  return $kw;
}

sub token_string {
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

sub _find_before {
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

__END__

=head1 NAME

Parser::HPC - parse HP-35s assembler source

=head1 DESCRIPTION

C<Parser::HPC> parses assembler source for the HP-35s calculator into a Perl
data structure. It supports the C<P35S> model and the data, code, and stack
segment forms described below.

=head1 SYNOPSIS

  use Parser::HPC;

  my $parser = Parser::HPC->new;
  my $program = $parser->from_string(<<'ASM');
  %TITLE "Example"
  MODEL P35S
  SEGMENT DATA
  FORMULA EQU 'A+B'
  ENDS
  SEGMENT main CODE
  start:
    LBL A
    0
    EQN FORMULA
    GTO start
    RTN
  ENDS main
  END start
  ASM

C<from_string> is provided by the parent class, L<Parser::MGC>. Parsing errors
are reported by that parser interface.

=head1 INPUT FORMAT

An input file may begin with a C<%TITLE> directive and must specify its model
with C<MODEL P35S>. It then contains one or more segments, each closed by
C<ENDS>, and ends with an C<END> directive. The C<END> directive may name a
code label as the program's start address.

Segments have the form C<SEGMENT [name] DATA>, C<SEGMENT [name] CODE>, or
C<SEGMENT [name] STACK>. The name is optional; unnamed data, code, and stack
segments are named C<_DATA>, C<_TEXT>, and C<STACK> in the result. A named
segment must be closed with its matching name, for example C<ENDS main>.

Data segments contain C<name EQU value> definitions. Values may be numbers or
quoted strings. Code segments contain labels, instructions, or literal values,
with one statement per line. A semicolon begins a comment through the end of
the line. Stack segments contain register assignments in the form
C<register SET number>.

The parser recognizes directives including C<%TITLE>, C<MODEL>, C<SEGMENT>,
C<ENDS>, C<END>, C<EQU>, and C<SET>. Although some additional directive names
are reserved internally, C<DISPLAY>, C<LOCALS>, C<NOLOCALS>, and C<RADIX> are
not implemented.

=head1 RETURN VALUE

The parse result is a hash reference with a C<model> field and a C<segments>
hash reference. Each segment entry has a C<type> of C<data>, C<code>, or
C<stack>. Data definitions are stored in C<definitions>; code statements are
stored in C<statements>; stack assignments are stored in C<assignments>.

The C<labels> field is undefined if no labels are declared; otherwise it is a
hash reference whose entries record each label's segment and zero-based
statement index. If supplied, the title is returned in C<title>, and the
upper-case start label is returned in C<startaddr>.

Code statements are represented as either C<instruction> or C<literal> entries.
Instructions carry their mnemonic and, when applicable, a typed operand;
literals carry a kind and value. For example, C<GTO start> produces an
instruction operand with type C<label> and value C<START>.

=head1 LIMITATIONS

Only the Polish notation mode is supported. Thousand-separator operations are
not implemented. The directives C<DISPLAY>, C<LOCALS>, C<NOLOCALS>, and
C<RADIX> are not supported.

=head1 SEE ALSO

L<Parser::MGC>, L<HP35s::Vocabulary>, C<bin/asm2hpc.pl>

=cut
