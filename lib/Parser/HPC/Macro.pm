package Parser::HPC::Macro;
# ABSTRACT: Simple macro parser for the HPC (HP calculators) module

# ------------------------------------------------------------------------
# Boilerplate
# ------------------------------------------------------------------------

use strict;
use warnings;

use version;
our $VERSION = version->declare('v0.5.0');

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
);

# -------------------------------------------------------------------------
# Parent class
# -------------------------------------------------------------------------

use parent 'Parser::MGC';

# -------------------------------------------------------------------------
# Define constants
# -------------------------------------------------------------------------

use constant pattern_ws => qr/[ \t]+/;

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
  );
  my $self = $class->SUPER::new(%args);
  $self->{_reserved} = { %reserved_symbols };
  return $self;
}

# -------------------------------------------------------------------------
# Overload existing Methods
# -------------------------------------------------------------------------

sub parse {
  my $self = shift;
  my %macros;
  my @output;
  my $local_id = 0;
  my $reference_parser = __PACKAGE__->new(
    toplevel => 'parse_code_references',
    patterns => { ident => $self->{patterns}->{ident} },
  );

  while (pos($self->{str}) < length($self->{str})) {
    my $definition = $self->maybe(
      sub { $self->parse_macro_definition(\%macros) }
    );
    if ($definition) {
      push @output, @{ $definition->{padding} };
      next;
    }

    my $expansion = $self->maybe(
      sub { $self->parse_macro_invocation(\%macros, \$local_id) }
    );
    if ($expansion) {
      push @output, @$expansion;
      next;
    }

    my $illegal_directive = $self->maybe(
      sub { $self->parse_out_of_scope_directive }
    );
    die "Can't use this outside macro\n" if $illegal_directive;

    my ($line, $ending) = $self->parse_source_line;
    $reference_parser->{macros} = \%macros;
    $reference_parser->from_string($line);
    push @output, $line, $ending;
  }

  return join '', @output;
}

sub parse_code_references {
  my $self = shift;

  while (pos($self->{str}) < length($self->{str})) {
    $self->skip_ws;
    last if pos($self->{str}) >= length($self->{str});

    if (defined $self->maybe_expect(';')) {
      $self->substring_before(qr/\z/);
      last;
    }

    my $position = $self->pos;
    my $next = $self->take(1);
    pos($self->{str}) = $position;
    if ($next eq q{'} || $next eq q{"}) {
      my $string = $self->maybe(sub { $self->token_string });
      unless (defined $string) {
        $self->take(length($self->{str}) - $self->pos);
        last;
      }
      next;
    }

    my $identifier = $self->maybe(sub { $self->token_ident });
    if (defined $identifier) {
      exists $self->{macros}->{uc $identifier}
        and die "Can't use macro name in expression: $identifier\n";
      next;
    }

    $self->take(1);
  }

  return 1;
}

sub parse_macro_definition {
  my ($self, $macros) = @_;
  my $keyword = $self->maybe_expect(qr/MACRO\b/);
  defined $keyword or $self->fail("Expected MACRO");
  $self->commit;

  my $name = $self->maybe(sub { $self->token_ident });
  defined $name or die $self->at_line_end
    ? "Missing macro ID\n" : "Illegal macro name\n";
  $self->expect_identifier_boundary("Illegal macro name");
  exists $self->{_reserved}->{uc $name}
    and die "Illegal macro name\n";

  my $arguments = $self->parse_identifier_list("Illegal macro argument");
  my %seen;
  for my $argument (@$arguments) {
    $seen{uc $argument}++
      and die "Duplicate dummy argument: $argument\n";
  }

  my @padding;
  my $header_ending = $self->parse_line_ending;
  push @padding, $header_ending if length $header_ending;

  my @body;
  my @locals;
  my %seen_symbols = map { uc($_) => 1 } @$arguments;
  my $terminated = 0;
  while (pos($self->{str}) < length($self->{str})) {
    my $directive = $self->maybe(
      sub { $self->parse_body_directive }
    );
    if (defined $directive) {
      if ($directive eq 'ENDM') {
        my $ending = $self->parse_line_ending;
        push @padding, $ending if length $ending;
        $terminated = 1;
        last;
      }
      if ($directive eq 'LOCAL') {
        my $names = $self->parse_identifier_list("Illegal local argument");
        @$names or die "Illegal local argument\n";
        for my $local (@$names) {
          $seen_symbols{uc $local}++ and die "Illegal local argument\n";
          push @locals, $local;
        }
        my $ending = $self->parse_line_ending;
        push @padding, $ending if length $ending;
        next;
      }
      die "Directive not allowed inside macro definition\n";
    }

    my ($line, $ending) = $self->parse_source_line;
    push @body, $line . $ending;
    push @padding, $ending if length $ending;
  }
  $terminated or die "Can't use this outside macro: missing ENDM\n";

  my $key = uc $name;
  $macros->{$key} = {
    arguments => $arguments,
    locals    => \@locals,
    body      => \@body,
  };

  return { padding => \@padding };
}

sub parse_macro_invocation {
  my ($self, $macros, $local_id) = @_;
  my $name = $self->maybe(sub { $self->token_ident });
  defined $name or $self->fail("Expected macro invocation");
  my $macro = $macros->{uc $name};
  defined $macro or $self->fail("Not a macro invocation");
  $self->commit;

  my $arguments = $self->list_of(',', sub {
    $self->generic_token('macro argument', qr/[^\s,;]+/)
  });
  @$arguments == @{ $macro->{arguments} }
    or die "Incorrect number of macro arguments for $name\n";

  $self->parse_line_ending;
  my %substitutions = map {
    $macro->{arguments}->[$_] => $arguments->[$_]
  } 0 .. $#$arguments;
  for my $local (@{ $macro->{locals} }) {
    $substitutions{$local} = sprintf('??%04d', $$local_id++);
  }
  my @expansion;
  for my $body_line (@{ $macro->{body} }) {
    my $expanded = $body_line;
    for my $symbol (keys %substitutions) {
      my $replacement = $substitutions{$symbol};
      $expanded =~ s/(?<![[:alnum:]_\@\$?])\Q$symbol\E(?![[:alnum:]_\@\$?])/$replacement/ig;
    }
    push @expansion, $expanded;
  }

  return \@expansion;
}

sub parse_body_directive {
  my $self = shift;
  $self->skip_ws;
  my $directive = $self->maybe_expect(qr/(?:ENDM|MACRO|LOCAL)\b/);
  defined $directive or $self->fail("Expected macro body directive");
  $self->commit;
  return uc $directive;
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
  my $line = $self->substring_before(qr/[\r\n]/);
  my $ending = $self->maybe_expect(qr/\r\n|\r|\n/);
  return ($line, defined $ending ? $ending : '');
}

sub line_has_statement {
  my ($self, $line) = @_;
  my $parser = __PACKAGE__->new(
    toplevel => 'parse_line_presence',
    patterns => { ident => $self->{patterns}->{ident} },
  );
  return $parser->from_string($line);
}

sub parse_line_presence {
  my $self = shift;
  my $has_statement = !$self->at_line_end;
  $self->substring_before(qr/\z/);
  return $has_statement;
}

sub parse_identifier_list {
  my ($self, $error) = @_;
  my @identifiers;
  my $identifier = $self->maybe(sub { $self->token_ident });
  unless (defined $identifier) {
    return \@identifiers if $self->at_line_end;
    die "$error\n";
  }

  $self->expect_identifier_boundary($error);
  push @identifiers, $identifier;
  while (defined $self->maybe_expect(',')) {
    $identifier = $self->maybe(sub { $self->token_ident });
    defined $identifier or die "$error\n";
    $self->expect_identifier_boundary($error);
    push @identifiers, $identifier;
  }

  return \@identifiers;
}

sub expect_identifier_boundary {
  my ($self, $error) = @_;
  my $position = $self->pos;
  my $next = $self->take(1);
  pos($self->{str}) = $position;
  !length($next) || $next =~ /[\s,;]/ or die "$error\n";
}

sub at_line_end {
  my $self = shift;
  my $position = $self->pos;
  $self->skip_ws;
  $self->maybe_expect(qr/;[^\r\n]*/);
  $self->skip_ws;
  my $at_end = defined $self->maybe_expect(qr/\r\n|\r|\n|\z/);
  pos($self->{str}) = $position;
  return $at_end;
}

sub parse_line_ending {
  my $self = shift;
  $self->skip_ws;
  $self->maybe_expect(qr/;[^\r\n]*/);
  $self->skip_ws;
  my $ending = $self->maybe_expect(qr/\r\n|\r|\n/);
  return $ending if defined $ending;
  pos($self->{str}) >= length($self->{str})
    or die "Extra characters after macro directive\n";
  return '';
}

1;

__END__

=head1 NAME

Parser::HPC::Macro - parse and expand HPC multiline macros

=head1 DESCRIPTION

This internal parser handles the IDEAL-mode C<MACRO> and C<ENDM> directives
before source is passed to L<Parser::HPC>. It collects macro definitions,
checks invocation arguments, substitutes dummy arguments as plain text, and
replaces each invocation with the expanded body.

The caller supplies the identifier pattern and reserved symbol names when
constructing the parser. Macro identifiers may not conflict with the HPC or
HP-35s vocabulary.

=head1 SUPPORTED SYNTAX

  MACRO name [arg1 [, arg2, ...]]
    macro body
  ENDM

Arguments are simple identifiers and are substituted literally at each
invocation. A leading C<LOCAL name [, name ...]> declaration gives each local
name a distinct symbol on each expansion. These names are separate
from labels controlled by the C<LOCALS> directive.

=head1 LIMITATIONS

Nested macro definitions, invocations of other macros from within a macro
body, and special macro-argument operators are not supported.

=cut
