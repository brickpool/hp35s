#!/usr/bin/perl
#
# (c) 2019 brickpool
#     J.Schneider (http://github.com/brickpool/)
#
# This script converts an assembler program to HP35s native program code
#
#######################################################################
#
# Changelog: 
#   2019-04-09: Initial version (0.1) created
#   2019-05-02: Version 0.2 Rename File, use of Parser::HPC
#   2019-05-06: fixing unicode handling (0.2.1)
#   2019-05-07: fixing sime minor bugs (0.2.2)

use strict;
use warnings;

use Getopt::Long;
use Parser::HPC;
use Data::Dumper;

# Declaration
my $VERSION = '0.2.2';
my $version;
my $unicode;
my $help;
my $debug;
my $file;
# the next line is only for perl debugging
#$file = 'test.asm';

Getopt::Long::Configure('bundling');
GetOptions (
  "help"      => \$help,    "h"   => \$help,
  "version"   => \$version, "v"   => \$version,
  "unicode"   => \$unicode, "u"   => \$unicode,
  "debug"                         => \$debug,
  "file=s"    => \$file,    "f=s" => \$file,
);
# Check command line arguments
&version()    if $version;
&help()       if $help;
$debug        = 0 unless defined $debug;

my $parser = Parser::HPC->new;

# unicode char
use constant _macr    => "\N{U+00AF}";
use constant _sup2    => "\N{U+00B2}";
use constant _times   => "\N{U+00D7}";
use constant _divide  => "\N{U+00F7}";
use constant _ycirc   => "\N{U+0177}";
use constant _int     => "\N{U+222B}";
use constant _ymacr   => "\N{U+0233}";
use constant _supx    => "\N{U+02E3}";
use constant _rtrif   => "\N{U+25B8}";
use constant _xcirc   => "x\N{U+0302}";
use constant _Sigma   => "\N{U+03A3}";
use constant _pi      => "\N{U+03C0}";
use constant _sigma   => "\N{U+03C3}";
use constant _larr    => "\N{U+2190}";
use constant _uarr    => "\N{U+2191}";
use constant _rarr    => "\N{U+2192}";
use constant _darr    => "\N{U+2193}";
use constant _radic   => "\N{U+221A}";
use constant _ne      => "\N{U+2260}";
use constant _le      => "\N{U+2264}";
use constant _ge      => "\N{U+2265}";
use constant _iscr    => "\N{U+1D4BE}";

my $unicodes = {
  # G1
  '*'     => _times,
  '/'     => _divide,
  # G2
  '10^x'  => '10'._supx,
  'pi'    => _pi,
  'Z+'    => _Sigma.'+',
  'Z-'    => _Sigma.'-',
  # G3
  '$FN_d' => _int.'FN d',
  # G3
  'Zx'    => _Sigma.'x',
  'Zx^2'  => _Sigma.'x'._sup2,
  'Zxy'   => _Sigma.'xy',
  'Zy'    => _Sigma.'y',
  'Zy^2'  => _Sigma.'y'._sup2,
  'zx'    => _sigma.'x',
  'zy'    => _sigma.'y',
  # G5
  '->°C'  => _rarr.'°C',
  # G6
  'CLZ'   => 'CL'._Sigma,
  '->CM'  => _rarr.'CM',
  '->DEG' => _rarr.'DEG',
  # G7
  '->ENG' => _rarr.'ENG',
  'ENG->' => 'ENG'._rarr,
  'e^x'   => 'e'._supx,
  # G8
  '->°F'  => _rarr.'°F',
  '->GAL' => _rarr.'GAL',
  # G9
  '->HMS' => _rarr.'HMS',
  'HMS->' => 'HMS'._rarr,
  '->IN'  => _rarr.'IN',
  'INT/'  => 'INT'._divide,
  # G10
  '->KG'  => _rarr.'KG',
  '->KM'  => _rarr.'KM',
  '->L'   => _rarr.'L',
  '->LB'  => _rarr.'LB',
  # G11
  '->MILE'=> _rarr.'MILE',
  # G12
  'RCL*'  => 'RCL'._times,
  'RCL/'  => 'RCL'._divide,
  '->RAD' => _rarr.'RAD',
  # G13
  'Rv'    => 'R'._darr,
  'R^'    => 'R'._uarr,
  # G14
  'STO*'  => 'STO'._times,
  'STO/'  => 'STO'._divide,
  # G15
  'sx'    => _sigma.'x',
  'sy'    => _sigma.'y',
  'x^2'   => 'x'._sup2,
  'sqrt'  => _radic.'x',
  'xroot' => 'x'._radic.'y',
  '\=x'   => 'x'._macr,
  '\^x'   => _xcirc,
  # G16
  '\=xw'  => 'x'._macr.'w',
  'x!=y?' => 'x'._ne.'y?',
  'x<=y?' => 'x'._le.'y?',
  'x>=y?' => 'x'._ge.'y?',
  # G17
  'x!=0?' => 'x'._ne.'0?',
  'x<=0?' => 'x'._le.'0?',
  'x>=0?' => 'x'._ge.'0?',
  # G18
  'xiy'   => 'x'._iscr.'y',
  'x+yi'  => 'x+y'._iscr,
  '\=y'   => _ymacr,
  '\^y'   => _ycirc,
  'y^x'   => 'y'._supx,
  #
  '<-'    => _larr,
  '->'    => _rarr,
  '\>'    => _rtrif,
};

my $lbl = '0';
my $loc = $0;
my $out = '';
my $response;

###############################
# Here is the main program 

if (defined $file) {
  open(STDIN, "< $file") or die "Can't open $file : $!";
}

### read the stdin and get the response
$response = $parser->from_file( \*STDIN );
print STDERR Dumper( $response ) if $debug;

# sort segments in alpabetic order
my @segments = sort keys %{ $response->{segments} };

# get all equations over all segments
my $equations = {};
foreach my $seg ( @segments ) {
  next if $response->{segments}->{$seg}->{type} ne 'data';

  defined $response->{segments}->{$seg}->{definitions} or
    print STDERR "Warn: no definitions for segment '$seg'\n" and next;

  my $definitions = $response->{segments}->{$seg}->{definitions};

  foreach my $definition ( keys %$definitions ) {
    next if $definitions->{$definition}->{type} ne 'equation';
    defined $definitions->{$definition}->{value} or
      print STDERR "Warn: missing 'value' for definition '$definition'\n" and next;

    my $equation = $definitions->{$definition}->{value};
    $equations->{$definition} = $equation;
  }
}

### first handle the stack segment
foreach my $seq ( @segments ) {
  # test if it is a stack segment
  next unless $response->{segments}->{$seq}->{type} eq 'stack';

  # get all register assignments
  my $assignments = $response->{segments}->{$seq}->{assignments};
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
    $out .= sprintf("%s%03d\t%s\n", $lbl, ++$loc, $_);
  }

  # only one stack segment is supported yet
  last;
}

### now handle all code segments
foreach my $seq ( @segments ) {
  # test if it is a stack segment
  next unless $response->{segments}->{$seq}->{type} eq 'code';

  # get all statements
  my $statements = $response->{segments}->{$seq}->{statements};
  for ( my $line = 0; $line < scalar @$statements; $line++ ) {
    my ($statement, $entry) = each %{ @$statements[$line] };
    defined $entry->{type} or
      print STDERR "Warn: missing 'type' in statement '$statement'\n" and next;

    if ($entry->{type} eq 'number') {
      my $number = $statement;
      $out .= sprintf("%s%03d\t%s\n", $lbl, ++$loc, $number);
    }

    elsif ($entry->{type} eq 'instruction') {
      my $mnemonic = $statement;
      # instructions without an operand
      if ( grep { $_ eq $mnemonic } @instructions ) {
        $out .= sprintf("%s%03d\t%s\n", $lbl, ++$loc, $mnemonic);
      }

      # instructions with an address: GTO and XEQ
      elsif ( grep { $_ eq $mnemonic } @with_address ) {

        # absolute address
        if ( defined $entry->{address} ) {
          my $addr = $entry->{address};
          $out .= sprintf("%s%03d\t%s %s\n", $lbl, ++$loc, $mnemonic, $addr);
        }

        # address label
        elsif ( defined $entry->{label} ) {
          my $label = $entry->{label};
          defined $response->{labels}->{$label}->{segment} or
            print STDERR "Warn: missing 'label' for instruction '$mnemonic'\n" and next;

          if ( $response->{labels}->{$label}->{segment} eq $seq ) {
            my $near = $response->{labels}->{$label}->{statement} + $line - $loc + 1;
            $out .= sprintf("%s%03d\t%s %s%03d\n", $lbl, ++$loc, $mnemonic, $lbl, $near);
          }
          else {
            print STDERR "Warn: far 'label' not supported yet\n";
            my $far = $response->{labels}->{$label}->{segment};
            my $near = $response->{labels}->{$label}->{statement} + 1;
            $out .= sprintf("%s%03d\t%s %s+%03d\n", $lbl, ++$loc, $mnemonic, $far, $near);
          }
        }

        # unknown operand
        else {
          print STDERR "Warn: missing type 'address' or 'label' in instruction '$mnemonic'\n";
          next;
        }
      }

      # instructions with a variable: LBL, INPUT, VIEW, STO, ...
      elsif ( grep { $_ eq $mnemonic } @with_variables, @with_indirects ) {
        defined $entry->{variable} or
          print STDERR "Warn: missing type 'variable' in instruction '$mnemonic'\n" and next;

        my $variable = $entry->{variable};
        if ($mnemonic =~ /LBL/) {
          # set line number if instruction is 'LBL'
          $lbl = $variable;
          $loc = 0;
        }
        my $space = $variable =~ /\([IJ]\)/ ? '' : ' ';   # indirects have no space
        $out .= sprintf("%s%03d\t%s%s%s\n", $lbl, ++$loc, $mnemonic, $space, $variable);
      }

      # instructions with a number: CF, FIX, ...
      elsif ( grep { $_ eq $mnemonic } @with_digits ) {
        defined $entry->{number} or
          print STDERR "Warn: missing type 'number' in instruction '$mnemonic'\n" and next;

        my $number = $entry->{number};
        $out .= sprintf("%s%03d\t%s %s\n", $lbl, ++$loc, $mnemonic, $number);
      }

      # instructions with an expression: EQN
      elsif ( grep { $_ eq $mnemonic } @expressions ) {
      
        # expression
        if ( defined $entry->{expression} ) {
          my $expression = $entry->{expression};
          $out .= sprintf("%s%03d\t%s\n", $lbl, ++$loc, $expression);
        }
        # equation
        elsif ( defined $entry->{equation} ) {
          my $definition = $entry->{equation};
          defined $equations->{$definition} or
            print STDERR "Warn: missing 'equation' for instruction '$mnemonic'\n" and next;

          my $equation = $equations->{$definition};
          $out .= sprintf("%s%03d\t%s\n", $lbl, ++$loc, $equation);
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
      print STDERR "Warn: unknown statement '$statement'\n";
    }
  }
}

### print to STDOUT

# option --unicode 
if ($unicode) {
  foreach (keys %$unicodes) {
    my $a = quotemeta $_;
    my $b = $unicodes->{$_};
    $out =~ s/$a/$b/g;
  }
  # roll back for 1/x
  my $inv = '1'._divide.'x';
  $out =~ s/$inv/1\/x/g;
  binmode(STDOUT, ":utf8");
}

print $out;

###############################
# Here are the subs 

sub version () {
  print "$1 ($VERSION) - by J.Schneider http://www.brickpool.de/\n" if $0 =~ /([^\/\\]+)$/;
  exit 0;
}

sub help () {
  print <<USE;
USAGE:
  c:\> type <asm-file> | perl asm2hpc.pl [options] 1> outfile.35s 2> outfile.err

VERSION: $VERSION
  Web: http://www.brickpool.de/
  
OPTIONS:
  -h, --help          Print this text
  -v, --version       Prints version
  -u, --unicode       Print Unicode to STDOUT
  --debug             Show debug information on STDERR

  --file=<asm-file>:
    Location of asm-file (Default is STDIN)

This script converts an assembler program to HP35s native program code
The output will be sent to STDOUT

USE
  exit 0;
};
