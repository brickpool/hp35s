#!/usr/bin/perl
use Parser::HPC;
use Data::Dumper;

use strict;
use warnings;

my $parser = Parser::HPC->new;

my $result = $parser->from_file( \*DATA );

print STDERR Dumper( $result );

my $regex_instructions    = join '|', map { quotemeta $_ } @instructions;
my $regex_with_address    = join '|', map { quotemeta $_ } @with_address;
my $regex_with_digits     = join '|', map { quotemeta $_ } @with_digits;
my $regex_with_variables  = join '|', map { quotemeta $_ } @with_variables, @with_indirects;
my $regex_expressions     = join '|', map { quotemeta $_ } @expressions;

my $lbl = '0';
my $loc = $0;

# sort segments in alpabetic order
my @segments = sort keys %{ $result->{segments} };

# get all equations over all segments
my $equations = {};
foreach my $seg ( @segments ) {
  next if $result->{segments}->{$seg}->{type} ne 'data';

  defined $result->{segments}->{$seg}->{definitions} or
    print STDERR "Warn: no definitions for segment '$seg'\n" and next;

  my $definitions = $result->{segments}->{$seg}->{definitions};

  foreach my $definition ( keys %$definitions ) {
    next if $definitions->{$definition}->{type} ne 'equation';
    defined $definitions->{$definition}->{value} or
      print STDERR "Warn: missing 'value' for definition '$definition'\n" and next;

    my $equation = $definitions->{$definition}->{value};
    $equations->{$definition} = $equation;
  }
}

# first handle the stack segment
foreach my $seq ( @segments ) {
  # test if it is a stack segment
  next unless $result->{segments}->{$seq}->{type} eq 'stack';

  # get all register assignments
  my $assignments = $result->{segments}->{$seq}->{assignments};
  my @register = ();
  foreach my $set (keys %$assignments) {
    next unless $assignments->{$set}->{type} eq 'register';
    push @register, $set;
  }

  # sort register in stack order
  my $sequence = {
    REGT => 1, REGZ => 2, REGY => 3, REGX => 4,
  };
  @_ = sort { $sequence->{$a} <=> $sequence->{$b} } @register;
  @register = @_;

  # build stack
  my @stack = ();
  foreach my $reg ( @register ) {
    my $value = $assignments->{$reg}->{value};
    # t, z, y, x
    if ($reg =~ /REGT/) {
      push @stack, $value;  # x, t, z, [v]
      push @stack, 'Rv';    # [v], z, y, x
    }
    elsif ($reg =~ /REGZ/) {
      push @stack, 'R^';    # z, y, x, t
      push @stack, $value;  # y, x, t, [v]
      push @stack, 'Rv';    # [v], y, x, t
      push @stack, 'Rv';    # t, [v], y, x
    }
    elsif ($reg =~ /REGY/) {
      push @stack, 'Rv';    # x, t, z, y
      push @stack, 'Rv';    # y, x, t, z
      push @stack, $value;  # x, t, z, [v]
      push @stack, 'R^';    # t, z, [v], x
    }
    elsif ($reg =~ /REGX/) {
      push @stack, 'Rv';    # x, t, z, y
      push @stack, $value;  # t, z, y, [v]
    }
    else {
      print STDERR "Warn: unknow register $reg\n";
    }
  }

  # optimize stack roll
  my $str = join(' ', @stack);
  $str =~ s/Rv\s+Rv\s+Rv/R\^/g;
  $str =~ s/R\^\s+R\^\s+R\^/Rv/g;
  $str =~ s/R\^\s+Rv//g;
  $str =~ s/Rv\s+R\^//g;
  $str =~ s/\s+/ /g;
  @stack = split /\s/, $str;

  # print stack
  foreach (@stack) {
    print sprintf("%s%03d\t%s\n", $lbl, ++$loc, $_);
  }
  
  # only one stack segment is supported
  last;
}

# now handle all code segments
foreach my $seq ( @segments ) {
  # test if it is a stack segment
  next unless $result->{segments}->{$seq}->{type} eq 'code';

  # get all statements
  my $statements = $result->{segments}->{$seq}->{statements};
  for ( my $line = 0; $line < scalar @$statements; $line++ ) {
    my ($statement, $entry) = each %{ @$statements[$line] };
    defined $entry->{type} or
      print STDERR "Warn: missing 'type' in statement '$statement'\n" and next;

    if ($entry->{type} eq 'number') {
      my $number = $statement;
      print sprintf("%s%03d\t%s\n", $lbl, ++$loc, $number);
    }

    elsif ($entry->{type} eq 'instruction') {
      my $mnemonic = $statement;
      # instructions without an operand
      if ($mnemonic =~ qr/$regex_instructions/) {
        print sprintf("%s%03d\t%s\n", $lbl, ++$loc, $mnemonic);
      }
  
      # instructions with an address: GOTO and XEQ
      elsif ($mnemonic =~ qr/$regex_with_address/ ) {
  
        # absolut address
        if ( defined $entry->{address} ) {
          my $addr = $entry->{address};
          print sprintf("%s%03d\t%s %s\n", $lbl, ++$loc, $mnemonic, $addr);
        }
  
        # address label
        elsif ( defined $entry->{label} ) {
          my $label = $entry->{label};
          defined $result->{labels}->{$label}->{segment} or
            print STDERR "Warn: missing 'label' for instruction '$mnemonic'\n" and next;
  
          if ( $result->{labels}->{$label}->{segment} eq $seq ) {
            my $near = $result->{labels}->{$label}->{statement} + $line - $loc + 1;
            print sprintf("%s%03d\t%s %s%03d\n", $lbl, ++$loc, $mnemonic, $lbl, $near);
          }
          else {
            print STDERR "Warn: far 'label' not supported yet\n";
            my $far = $result->{labels}->{$label}->{segment};
            my $near = $result->{labels}->{$label}->{statement} + 1;
            print sprintf("%s%03d\t%s %s+%03d\n", $lbl, ++$loc, $mnemonic, $far, $near);
          }
        }
  
        # unknown operand
        else {
          print STDERR "Warn: missing type 'address' or 'label' in instruction '$mnemonic'\n";
          next;
        }
      }
  
      # instructions with a variable: LBL, INPUT, VIEW, STO, ...
      elsif ($mnemonic =~ qr/$regex_with_variables/) {
        defined $entry->{variable} or
          print STDERR "Warn: missing type 'variable' in instruction '$mnemonic'\n" and next;
  
        my $variable = $entry->{variable};
        if ($mnemonic =~ /LBL/) {
          # set line number if instruction is 'LBL'
          $lbl = $variable;
          $loc = 0;
        }
        print sprintf("%s%03d\t%s %s\n", $lbl, ++$loc, $mnemonic, $variable);
      }
  
      # instructions with a number: CF, FIX, ...
      elsif ($mnemonic =~ qr/$regex_with_digits/) {
        defined $entry->{number} or
          print STDERR "Warn: missing type 'number' in instruction '$mnemonic'\n" and next;
  
        my $number = $entry->{number};
        print sprintf("%s%03d\t%s %s\n", $lbl, ++$loc, $mnemonic, $number);
      }
  
      # instructions with an expression: EQN
      elsif ($mnemonic =~ qr/$regex_expressions/) {
      
        # expression
        if ( defined $entry->{expression} ) {
          my $expression = $entry->{expression};
          print sprintf("%s%03d\t%s\n", $lbl, ++$loc, $expression);
        }
        # equation
        elsif ( defined $entry->{equation} ) {
          my $definition = $entry->{equation};
          defined $equations->{$definition} or
            print STDERR "Warn: missing 'equation' for instruction '$mnemonic'\n" and next;
  
          my $equation = $equations->{$definition};
          print sprintf("%s%03d\t%s\n", $lbl, ++$loc, $equation);
        }
        
        # unknown operand
        else {
          print STDERR "Warn: missing type 'expression' or 'equation' in instruction '$mnemonic'\n";
          next;
        }
      }
  
      # unknown instruction
      else {
        print STDERR "Warn: unknown instruction '$mnemonic'\n";
      }
    }

    # unknown statement
    else {
      print STDERR "Warn: unknown instruction '$statement'\n";
    }
  }
}

1;






__DATA__
; Example
MODEL P35S          ; actually only HP35s is permitted

SEGMENT STACK
  REGX SET 1.0
  REGY SET 2.0
  REGT SET 4
  REGZ SET 3
ENDS

SEGMENT DATA
  str EQU '1+2+3'   ; string
  i   EQU 4         ; unsigned integer
  j   EQU -5        ; signed integer
  f   EQU 6.7       ; float
  one EQU 1
ENDS

; Body of program A goes here
SEGMENT program_A CODE
start_A:
  LBL A
  FS? 1
    GOTO start_A
  RADIX.
  EQN one
  +
  XOR
  Z+
  EQN str           ; =6
  Zx
  R^
  EQN '2+3'         ; =5
  Rv
  STO Z
  VIEW Z
return:
  RTN
ENDS program_A

SEGMENT program_B CODE
start_B:
  LBL B
  INPUT I
  x<>(I)
    GOTO start_A
end_B:
  RTN
ENDS program_B

END start_A         ; program entry point
