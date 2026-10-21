package Parser::HPC::Macro;
# ABSTRACT: Simple macro parser for the HPC (HP calculators) module

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
);
use Parser::HPC::Vocabulary qw(
  @directives
  @predefined
  @languages
  @segments
  @listings
);

# -------------------------------------------------------------------------
# Parent class
# -------------------------------------------------------------------------

use parent 'Parser::MGC';

# -------------------------------------------------------------------------
# Define constants
# -------------------------------------------------------------------------

# overwrite existing patterns
use constant pattern_comment => qr/;.*\n/;

# -------------------------------------------------------------------------
# Constructor
# -------------------------------------------------------------------------

sub new {
  my ($class, %args) = @_;
  my %reserved_symbols = map { uc($_) => 1 } (
    @constants,
    @instructions,
    @with_address,
    @with_digits,
    @with_variables,
    @with_indirects,
    @expressions,
    @functions,
    @register,

    @directives,
    @predefined,
    @languages,
    @segments,
    @listings,
  );
  my $self = $class->SUPER::new(%args);
  $self->{_reserved} = { %reserved_symbols };
  return $self;
}

# -------------------------------------------------------------------------
# Overload existing Methods
# -------------------------------------------------------------------------

sub from_string {
  my ($self, $source) = @_;
  $source =~ s/\r\n?/\n/g;
  $source .= "\n" unless $source =~ /\n\z/;
  return $self->SUPER::from_string($source);
}

sub parse {
  my $self = shift;
  my %macros;
  my $local_id = 0;
  my $reference_parser = __PACKAGE__->new(
    toplevel => 'parse_code_references',
    patterns => { ident => $self->{patterns}->{ident} },
  );

  my $output = $self->sequence_of(sub {
    $self->commit;
    $self->any_of(
      sub {
        $self->parse_macro_definition(\%macros);
        return '';
      },
      sub { $self->parse_macro_invocation(\%macros, \$local_id) },
      sub {
        $self->parse_out_of_scope_directive;
        die "Can't use this outside macro\n";
      },
      sub {
        my $line = $self->parse_source_line;
        $reference_parser->{macros} = \%macros;
        $reference_parser->from_string($line);
        return "$line\n";
      },
    );
  });

  return join '', @$output;
}

sub parse_code_references {
  my $self = shift;

  $self->sequence_of(sub {
    $self->any_of(
      sub { $self->expect(qr/;[^\r\n]*/) },
      sub {
        $self->expect(qr/(?=['"])/);
        my $string = $self->maybe(sub { $self->token_string });
        $self->substring_before(qr/\z/) unless defined $string;
        return 1;
      },
      sub {
        my $identifier = $self->token_ident;
        exists $self->{macros}->{uc $identifier}
          and die "Can't use macro name in expression: $identifier\n";
        return $identifier;
      },
      sub { $self->generic_token(character => qr/./s) },
    );
  });

  return 1;
}

sub parse_macro_definition {
  my ($self, $macros) = @_;

  # MACRO ..
  $self->expect(qr/MACRO(?=[ \t])/);
  $self->commit;

  # retrieve the line after the commit
  my ($start_line) = $self->where;

  # MACRO name ..
  my $name = eval { $self->token_ident };

  # check whether we have left the line
  my ($line) = $self->where;
  defined $name && $start_line == $line
    or $self->fail("Missing macro ID");

  # check if the macro name is a reserved word
  !exists $self->{_reserved}->{uc $name}
    or $self->fail("Symbol already different kind");

  # parse macro arguments if present
  my $arguments = [];
  $self->skip_ws;
  ($line) = $self->where;
  if ( $start_line == $line ) {
    my %seen;
    $arguments = $self->list_of(',', sub {
      $self->commit;
      my $argument = eval { $self->token_ident };
      defined $argument 
        or $self->fail("Illegal macro argument");
      !$seen{uc $argument}++
        or $self->fail("Duplicate dummy argument: $argument");
      return $argument;
    });
  }

  # skip and throw an error if we're still on the same line
  $self->skip_ws;
  ($line) = $self->where;
  $start_line != $line 
    or $self->fail("Extra characters");

  my $block = $self->scope_of(
    undef,
    sub { $self->parse_macro_body },
    qr/ENDM(?=[\s;])/i,
  );

  # check whether we have left the line
  my ($end_line) = $self->where;
  $self->skip_ws;
  ($line) = $self->where;
  $end_line == $line
    and $self->fail("Extra characters");

  $macros->{uc $name} = {
    arguments => $arguments,
    locals    => $block->{locals},
    body      => $block->{body},
  };

  return $macros->{uc $name};
}

sub parse_macro_body {
  my $self = shift;
  my (@body, @locals);
  $self->sequence_of(sub {
    my $names = $self->parse_local;
    if (defined $names) {
      push @locals, @$names;
    }
    else {
      my $line = $self->parse_source_line;
      push @body, "$line\n";
    }
    return 1;
  });
  return { body => \@body, locals => \@locals };
}

sub parse_macro_invocation {
  my ($self, $macros, $local_id) = @_;

  # CALL name
  my $name = $self->maybe(sub { $self->token_ident });
  defined $name
    or $self->fail("Illegal instruction");
  my $macro = $macros->{uc $name};
  defined $macro
    or $self->fail("Illegal instruction");
  $self->commit;
  my ($line) = $self->where;

  # CALL name [argument [, argument]...]
  my $arguments = $self->list_of(',', sub {
    $self->skip_ws;
    my ($current_line) = $self->where;
    $current_line == $line
      or $self->fail("Illegal macro argument");
    $self->commit;
    my $argument = $self->maybe(sub {
      $self->generic_token( argument => qr/[^\s,;]+/ );
    });
    defined $argument
      or $self->fail("Illegal macro argument");
    return $argument;
  });
  @$arguments == @{ $macro->{arguments} }
    or $self->fail("Illegal macro argument");

  $self->skip_ws;
  my ($next_line) = $self->where;
  $next_line != $line
    or $self->fail("Extra characters on line");

  # Map dummy arguments to invocation values.
  my %substitutions = map {
    uc($macro->{arguments}->[$_]) => $arguments->[$_]
  } 0 .. $#$arguments;

  # Assign a unique identifier to each distinct local name.
  my %locals;
  for my $local (@{ $macro->{locals} }) {
    my $key = uc $local;
    next if exists $locals{$key};
    $locals{$key} = sprintf('??%04d', $$local_id++);
  }

  # Expand body lines using this invocation's replacement tables.
  my $expander = __PACKAGE__->new(
    toplevel => 'parse_substitutions',
    patterns => { ident => $self->{patterns}->{ident} },
  );
  $expander->{substitutions} = \%substitutions;
  $expander->{locals} = \%locals;

  return join '', map {
    $expander->from_string($_)
  } @{ $macro->{body} };
}

sub parse_substitutions {
  my $self = shift;
  my $identifier = $self->{patterns}->{ident};

  # Prefer local names over dummy arguments in address contexts.
  my $replace_address = sub {
    my ($symbol) = @_;
    my $key = uc $symbol;
    return $self->{locals}->{$key}
      // $self->{substitutions}->{$key}
      // $symbol;
  };

  my $expanded = $self->substring_before(qr/\S/);

  # Replace leading label declarations.
  $self->sequence_of(sub {
    my (undef, $name, $colon) =
      $self->expect(qr/($identifier)([ \t]*:)/);
    $expanded .= $replace_address->($name) . $colon;
    $expanded .= $self->substring_before(qr/\S/);
    return 1;
  });

  # Replace the operand of an address instruction.
  my $address = join '|', map { quotemeta $_ } @with_address;
  my $instruction = $self->maybe_expect(qr/(?:$address)(?=[ \t])/);
  if (defined $instruction) {
    $expanded .= $instruction . $self->substring_before(qr/\S/);
    my $operand = $self->maybe(sub { $self->token_ident });
    $expanded .= $replace_address->($operand) if defined $operand;
  }

  # Substitute only dummy arguments in the remaining text.
  $self->sequence_of(sub {
    $expanded .= $self->substring_before(qr/[[:alnum:]_\@\$?]/);
    return 1 if $self->at_eos;
    my $symbol = $self->generic_token(symbol => qr/[[:alnum:]_\@\$?]+/);
    $expanded .= $self->{substitutions}->{uc $symbol} // $symbol;
    return 1;
  });

  $expanded .= "\n" unless $expanded =~ /\n\z/;
  return $expanded;
}

sub parse_local {
  my $self = shift;

  # LOCAL ..
  defined $self->maybe_expect(qr/LOCAL(?=[ \t])/)
    or return;
  $self->commit;
  my ($line) = $self->where;

  # LOCAL symbol [, symbol]...
  my @symbols;
  $self->list_of(',', sub {
    $self->commit;
    my $symbol = eval { $self->token_ident };
    defined $symbol
      or $self->fail("Illegal local argument");
    !exists $self->{_reserved}->{uc $symbol}
      or $self->fail("Symbol already different kind");
    push @symbols, $symbol;
  });

  # check if symbols are present
  @symbols 
    or $self->fail("Illegal local argument");

  # skip and throw an error if we're still on the same line
  $self->skip_ws;
  my ($next_line) = $self->where;
  $line != $next_line
    or $self->fail( "Extra characters" );    # .. on line

  return \@symbols;
}

sub parse_out_of_scope_directive {
  my $self = shift;
  $self->skip_ws;
  my $directive = $self->maybe_expect(qr/(?:ENDM|LOCAL)\b/);
  defined $directive or $self->fail("Expected out-of-scope directive");
  $self->commit;
  return $directive;
}

sub parse_source_line {
  my $self = shift;
  my (undef, $line, $ending) = $self->expect(qr/([^\n]*)(\n|\z)/);
  return $line;
}

1;

__END__

=pod

=head1 NAME

Parser::HPC::Macro - expand macros in HP calculator assembler source code

=head1 SYNOPSIS

  use Parser::HPC::Macro;

  my $parser = Parser::HPC::Macro->new(
    patterns => {
      ident => $identifier_pattern,
    },
  );

  my $source = $parser->from_string($input);

=head1 DESCRIPTION

C<Parser::HPC::Macro> is a source-to-source preprocessor for macros in
HP calculator assembler source code.

Source productions are composed using L<Parser::MGC>'s C<sequence_of>,
C<any_of>, C<scope_of> and C<list_of> methods. Macro bodies form scopes
terminated by C<ENDM>. Token conversion performs symbol substitution.

The parser collects macro definitions and expands subsequent macro
invocations. Macro arguments are substituted into the macro body, and
local macro symbols are replaced with unique generated identifiers for
each expansion.

Unlike L<Parser::HPC>, this parser does not produce an abstract syntax
tree. Its normal entry point returns assembler source code with macro
definitions removed and macro invocations replaced by their expanded
bodies. The resulting source is suitable for subsequent parsing by
L<Parser::HPC>.

Macro names are case-insensitive for lookup and may not conflict with
reserved calculator or assembler symbols.

=head1 MACRO PROCESSING

=head2 Processing flow

The normal entry point invokes L</parse> through the
L<Parser::MGC> parser interface. Processing is performed sequentially
over the source:

  source code
    |
    v
  from_string()
    |
    v
  parse()
    |
    +-- parse_macro_definition()
    |     +-- scope_of(..., ENDM)
    |           '-- parse_macro_body()
    |                 +-- parse_local()
    |                 '-- expect(source line)
    |
    +-- parse_macro_invocation()
    |     '-- parse_substitutions()
    |
    +-- parse_out_of_scope_directive()
    |
    '-- parse_source_line()
          '-- parse_code_references()

Macro definitions are stored internally and do not appear in the
resulting source. The output uses LF line endings: C<from_string>
normalizes CRLF and CR line endings and adds a final newline when needed.

Macro invocations are replaced with their expanded body lines. Dummy
arguments are substituted with the corresponding invocation arguments.
Macro-local symbols are replaced with generated identifiers of the form
C<??NNNN>.

Ordinary source lines are emitted with normalized LF line endings.
Before a line is emitted, L</parse_code_references> checks identifiers
outside quoted strings and comments and rejects references to defined
macro names in expressions.

=head2 Macro definition

A parsed macro definition is stored internally in the following form:

  {
    arguments => [
      $argument,
      ...
    ],
    locals => [
      $local,
      ...
    ],
    body => [
      $source_line,
      ...
    ],
  }

C<arguments> contains the dummy argument names in declaration order.

C<locals> contains the names declared local to each macro expansion.

C<body> contains the source lines forming the macro body, including
their normalized LF line endings.

The macro name itself is used as the key in the internal macro table
after conversion to upper case.

The definition structure is internal to macro processing and is not
returned in the final expanded source.

=head2 Macro expansion

A macro invocation produces a scalar string containing the expanded
body lines, each terminated by a newline.

Each dummy argument is replaced by the corresponding invocation
argument.

Each macro-local symbol is assigned a generated identifier:

  ??0000
  ??0001
  ...

The identifier counter is shared across expansions performed during one
call to L</parse>, so generated local identifiers are distinct within
that preprocessing run.

Substitution matches complete identifiers without regard to case.
Replacement text is emitted directly and is not scanned again for
further substitutions.

Local names are replaced only in label declarations and address operands
of instructions from C<@with_address> in L<HP35s::Vocabulary>. In these
contexts, the local replacement takes precedence over a dummy argument
of the same name. Other occurrences use dummy argument substitution.
Repeated declarations of a local name share one generated identifier
per expansion.

=head1 CONSTRUCTOR

=head2 new

  my $parser = Parser::HPC::Macro->new(%args);

Creates a new macro parser.

Constructor arguments are passed to L<Parser::MGC>.

The constructor builds an internal case-insensitive set of reserved
symbols from the calculator vocabulary and the assembler vocabulary.
Reserved symbols cannot be used as macro names.

=head1 METHODS

=head2 parse

  my $source = $self->parse();

Processes the complete input and returns the resulting assembler source
as a scalar string.

Macro definitions are collected into an internal macro table and
removed from the emitted source without padding.

Macro invocations are replaced by the expanded source string returned by
L</parse_macro_invocation>.

Ordinary source lines are emitted with normalized LF line endings.

Encountering C<ENDM> or C<LOCAL> outside a macro definition terminates
processing with an error.

=head2 parse_code_references

  my $result = $self->parse_code_references();

Scans source text for identifier references.

Whitespace is skipped. Text following a semicolon is treated as a
comment and is not scanned. Quoted strings are skipped without checking
their contents.

Identifiers are compared case-insensitively with the macro table
supplied by the caller. Use of a defined macro name as an identifier in
the scanned source terminates processing with an error.

Returns C<1> after the input has been scanned successfully.

=head2 parse_local

  my $statement = $self->parse_local();

Parses C<LOCAL> followed by a comma-separated identifier list. Names
are checked against reserved symbols, but not against dummy arguments or
previous C<LOCAL> declarations.

Missing or invalid names report C<Illegal local argument>.
Additional input after the identifier list reports
C<Extra characters>.

Returns C<undef> when C<LOCAL> is absent, using normal parser whitespace
handling. Once the keyword is recognized, parsing is committed and
errors are reported through C<fail>, including the source position.

Returns an array reference containing the parsed names. The declaration
is not included in the expanded macro body.

=head2 parse_macro_body

  my $block = $self->parse_macro_body();

Parses a sequence of C<LOCAL> declarations and source lines
within the scope established by L</parse_macro_definition>.

C<LOCAL> is the only statement interpreted here. Other source lines are
retained for later parsing by L<Parser::HPC>. The enclosing C<scope_of>
handles C<ENDM>.

Returns a hash reference containing the C<body> lines and C<locals>
names.

=head2 parse_macro_definition

  my $definition = $self->parse_macro_definition($macros);

Parses one macro definition, stores it in C<$macros>, and returns the
stored macro definition.

The macro itself is stored in C<$macros> under its upper-case name:

  $macros->{uc $name} = {
    arguments => $arguments,
    locals    => $locals,
    body      => $body,
  };

C<arguments> is an array reference containing dummy argument names in
declaration order.

C<locals> is an array reference containing symbols that receive unique
generated names for each expansion.

C<body> is an array reference containing the source lines of the macro
body, each with a normalized LF line ending.

Duplicate dummy arguments are rejected. Macro-local names may have the
same spelling as dummy arguments or previously declared local names.
Reserved symbols cannot be used as macro names.

A macro definition must terminate with C<ENDM>.

=head2 parse_macro_invocation

  my $expansion = $self->parse_macro_invocation(
    $macros,
    \$local_id,
  );

Parses an invocation of a previously defined macro and returns a scalar
string containing the expanded source lines.

The number of invocation arguments must match the number of dummy
arguments stored in the macro definition.

Dummy arguments are replaced with their invocation values. Each distinct
local name receives a generated identifier based on C<$local_id>, used
for label declarations and address operands.

The supplied local identifier counter is incremented for each generated
local symbol.

The invocation line itself is consumed and is not included in the
returned expansion.

=head2 parse_out_of_scope_directive

  my $directive = $self->parse_out_of_scope_directive();

Recognizes a macro-only directive encountered outside a macro
definition.

Returns the matched C<ENDM> or C<LOCAL> directive. L</parse> treats
either result as an error.

=head2 parse_source_line

  my $line = $self->parse_source_line();

Consumes one physical source line and returns the line contents without the 
line-ending characters.

=head2 parse_substitutions

  my $expanded = $self->parse_substitutions();

Reads leading label declarations and an optional address instruction
identified through C<@with_address>. Label names and address operands
are looked up case-insensitively in the caller's C<locals> table, falling
back to the C<substitutions> table for dummy arguments.

The remaining source is scanned using symbol and text tokens. Only
dummy argument substitutions apply there, including inside quoted
strings and comments. Other text, whitespace and line endings are
preserved. Inserted replacement values are not parsed again.

Returns the expanded source as a scalar string. L</parse_macro_invocation>
uses this method as the entry point of its expansion parser.

=head1 SEE ALSO

L<Parser::HPC>, L<Parser::MGC>, L<HP35s::Vocabulary>,
L<Parser::HPC::Vocabulary>

The assembler macro syntax is documented in the project wiki.

=head1 AUTHOR

J. Schneider <brickpool@cpan.org>

=cut
