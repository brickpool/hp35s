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
#   2019-05-08: add r\theta{a}
#   2019-05-09: add option shortcut (0.3.0)
#   2019-05-10: fixing key sequences for CF, FIX, ... and EQN

use strict;
use warnings;

use Getopt::Long;
use Parser::HPC;
use Data::Dumper;

# Declaration
my $VERSION = '0.3.1';
my $version;
my $unicode;
my $shortcut;
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
  "shortcut"  => \$shortcut,"s"   => \$shortcut,
  "debug"                         => \$debug,
  "file=s"    => \$file,    "f=s" => \$file,
);
# Check command line arguments
&version()    if $version;
&help()       if $help;
$debug        = 0 unless defined $debug;

my $parser = Parser::HPC->new;

# unicode char
use constant _not     => "\N{U+00AC}";
use constant _macr    => "\N{U+00AF}";
use constant _sup2    => "\N{U+00B2}";
use constant _times   => "\N{U+00D7}";
use constant _divide  => "\N{U+00F7}";
use constant _ycirc   => "\N{U+0177}";
use constant _lsh     => "\N{U+21B0}";
use constant _rsh     => "\N{U+21B1}";
use constant _lArr    => "\N{U+21D0}";
use constant _int     => "\N{U+222B}";
use constant _ymacr   => "\N{U+0233}";
use constant _vltri   => "\N{U+22B2}";
use constant _vrtri   => "\N{U+22B3}";
use constant _supx    => "\N{U+02E3}";
use constant _xutri   => "\N{U+25B3}";
use constant _brtri   => "\N{U+25B6}";
use constant _xdtri   => "\N{U+25BD}";
use constant _xcirc   => "x\N{U+0302}";
use constant _Sigma   => "\N{U+03A3}";
use constant _theta   => "\N{U+03B8}";
use constant _pi      => "\N{U+03C0}";
use constant _sigma   => "\N{U+03C3}";
use constant _larr    => "\N{U+2190}";
use constant _uarr    => "\N{U+2191}";
use constant _rarr    => "\N{U+2192}";
use constant _darr    => "\N{U+2193}";
use constant _sqrt    => "\N{U+221A}";
use constant _neq     => "\N{U+2260}";
use constant _leq     => "\N{U+2264}";
use constant _geq     => "\N{U+2265}";
use constant _Cscr    => "\N{U+1D49E}";
use constant _iscr    => "\N{U+1D4BE}";

my $unicodes = {
  # G1
  '*'     => _times,
  '/'     => _divide,
  '<='    => _lArr,
  # G2
  '/->'   => _rsh,
  '<-\\'  => _lsh,
  '10^x'  => '10'._supx,
  'p'     => _pi,
  'pi'    => _pi,
  'Z+'    => _Sigma.'+',
  'Z-'    => _Sigma.'-',
  # G3
  'Zx'    => _Sigma.'x',
  'Zx^2'  => _Sigma.'x'._sup2,
  'Zxy'   => _Sigma.'xy',
  'Zy'    => _Sigma.'y',
  'Zy^2'  => _Sigma.'y'._sup2,
  'S,z'   => 'S,'._sigma,
  'zx'    => _sigma.'x',
  'zy'    => _sigma.'y',
  '$'     => _int,
  '$FN_d' => _int.'FN d',
  # G4
  't'     => _theta,
  # G5
  '->'    => _rarr,
  '->°C'  => _rarr.'°C',
  # G6
  'CLZ'   => 'CL'._Sigma,
  '->CM'  => _rarr.'CM',
  '->DEG' => _rarr.'DEG',
  # G7
  '<-'    => _larr,
  '<-ENG' => _larr.'ENG',
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
  'rta'   => 'r'._theta.'a',
  '->RAD' => _rarr.'RAD',
  'RCL*'  => 'RCL'._times,
  'RCL/'  => 'RCL'._divide,
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
  'sqrt'  => _sqrt.'x',
  'xroot' => 'x'._sqrt.'y',
  '\=x'   => 'x'._macr,
  '\^x'   => _xcirc,
  # G16
  '\=xw'  => 'x'._macr.'w',
  'x!=y?' => 'x'._neq.'y?',
  'x<=y?' => 'x'._leq.'y?',
  'x>=y?' => 'x'._geq.'y?',
  # G17
  'x!=0?' => 'x'._neq.'0?',
  'x<=0?' => 'x'._leq.'0?',
  'x>=0?' => 'x'._geq.'0?',
  # G18
  'xiy'   => 'x'._iscr.'y',
  'x+yi'  => 'x+y'._iscr,
  '\=y'   => _ymacr,
  '\^y'   => _ycirc,
  'y^x'   => 'y'._supx,
  #
  '\>'    => _brtri,
  'wedge' => _xutri,
  'lhd'   => _vltri,
  'rhd'   => _vrtri,
  'vee'   => _xdtri,
  '~'     => _not,
  'CAN'   => _Cscr,
};

my $sequences = {
  # G2
  '10^x'    => '/-> 10^x',
  '%'       => '/-> %',
  '%CHG'    => '<-\ %CHG',
  'p'       => '<-\ pi',
  'pi'      => '<-\ pi',
  'Z-'      => '<-\ Z-',
  # G3
  'Zx'      => '/-> SUMS 2',
  'Zx^2'    => '/-> SUMS 4',
  'Zxy'     => '/-> SUMS 6',
  'Zy'      => '/-> SUMS 3',
  'Zy^2'    => '/-> SUMS 4',
  'zx'      => '/-> S,z 3',
  'zy'      => '/-> S,z 4',
  '$FN_d'   => '<-\ $',
  # G4
  '['       => '/-> []',
  ']'       => '',
  't'       => '/-> t',
  'ABS'     => '/-> ABS',
  'ACOS'    => '/-> ACOS',
  'ACOSH'   => '<-\ HYP /-> ACOS',
  'ALG'     => 'MODE 4',
  'ALOG'    => '/-> 10^x',
  'ALL'     => '<-\ DISPLAY 4',
  'AND'     => '<-\ LOGIC 1',
  'ARG'     => '<-\ ARG',
  'ASIN'    => '/-> ASIN',
  'ASINH'   => '<-\ HYP /-> ASIN',
  'ATAN'    => '/-> ATAN',
  # G5
  'ATANH'   => '<-\ HYP /-> ATAN',
  'b'       => '<-\ L.R. 5',
  'BIN'     => '/-> BASE 4',
  '/c'      => '<-\ /c',
  '->°C'    => '/-> ->°C',
  'CF'      => '<-\ FLAGS 2',
  # G6
  'CLZ'     => '/-> CLEAR 4',
  'CLVARS'  => '/-> CLEAR 2',
  'CLx'     => '/-> CLEAR 1',
  'CLSTK'   => '/-> CLEAR 5',
  '->CM'    => '/-> ->cm',
  'nCr'     => '<-\ nCr',
  'COSH'    => '<-\ HYP COS',
  'DEC'     => '/-> BASE 1',
  'DEG'     => 'MODE 1',
  '->DEG'   => '/-> ->DEG',
  # G7
  'DSE'     => '/-> DSE',
  'ENG'     => '<-\ DISPLAY 3',
  'e^x'     => '/-> e^x',
  # G8
  'EXP'     => '/-> e^x',
  '->°F'    => '<-\ ->°F',
  'FIX'     => '<-\ DISPLAY 1',
  'FN='     => '<-\ FN=',
  'FP'      => '<-\ INTG 5',
  'FS?'     => '<-\ FLAGS 3',
  '->GAL'   => '<-\ ->gal',
  'GRAD'    => 'MODE 3',
  'HEX'     => '/-> BASE 2',
  # G9
  '->HMS'   => '/-> ->HMS',
  'HMS->'   => '<-\ HMS->',
  '->IN'    => '/-> ->in',
  'IDIV'    => '<-\ INTG 2',
  'INT/'    => '<-\ INTG 2',
  'INTG'    => '<-\ INTG 4',
  'INPUT'   => '<-\ INPUT',
  'INV'     => '1/x',
  # G10
  'IP'      => '<-\ INTG 6',
  'ISG'     => '<-\ ISG',
  '->KG'    => '/-> ->kg',
  '->KM'    => '/-> ->KM',
  '->L'     => '/-> ->l',
  'LASTx'   => '/-> LASTx',
  '->LB'    => '/-> ->lb',
  'LBL'     => '/-> LBL',
  'LN'      => '/-> LN',
  'LOG'     => '<-\ LOG',
  'm'       => '<-\ L.R. 4',
  # G11
  '->MILE'  => '/-> ->MILE',
  'n'       => '/-> SUMS 1',
  'NAND'    => '<-\ LOGIC 5',
  'NOR'     => '<-\ LOGIC 6',
  'NOT'     => '<-\ LOGIC 4',
  'OCT'     => '/-> BASE 3',
  'OR'      => '<-\ LOGIC 3',
  'nPr'     => '/-> nPr',
  'PSE'     => '/-> PSE',
  # G12
  'r'       => '<-\ L.R. 3',
  'rta'     => '<-\ DISPLAY 1 0',
  'RAD'     => 'MODE 1',
  '->RAD'   => '<-\ ->RAD',
  'RADIX,'  => '<-\ DISPLAY 6',
  'RADIX.'  => '<-\ DISPLAY 5',
  'RADOM'   => '/-> RADOM',
  'RCL+'    => 'RCL +',
  'RCL-'    => 'RCL -',
  'RCL*'    => 'RCL *',
  'RCL/'    => 'RCL /',
  'RMDR'    => '<-\ INTG 3',
  # G13
  'RND'     => '<-\ RND',
  'RPN'     => 'MODE 5',
  'RTN'     => '<-\ RTN',
  'R^'      => '/-> R^',
  'SCI'     => '<-\ DISPLAY 2',
  'SEED'    => '<-\ SEED',
  'SF'      => '<-\ FLAGS 1',
  'SGN'     => '<-\ INTG 1',
  # G14
  'SINH'    => '<-\ HYP SIN',
  'SQ'      => '/-> x^2',
  'SQRT'    => 'sqrt',
  'STO'     => '/-> STO',
  'STO+'    => '/-> STO +',
  'STO-'    => '/-> STO -',
  'STO*'    => '/-> STO *',
  'STO/'    => '/-> STO /',
  'STOP'    => 'R/S',
  # G15
  'sx'      => '/-> S,z 1',
  'sy'      => '/-> S,z 2',
  'TANH'    => '<-\ HYP TAN',
  'VIEW'    => '<-\ VIEW',
  'x^2'     => '/-> x^2',
  'xroot'   => '<-\ xroot',
  '\=x'     => '<-\ \=x,\=y 1',
  '\^x'     => '<-\ L.R. 1',
  '!'       => '/-> !',
  # G16
  'XROOT'   => '<-\ xroot',
  '\=xw'    => '<-\ \=x,\=y 3',
  'x<>'     => '<-\ x<>y',
  'x!=y?'   => '<-\ x?y 1',
  'x<=y?'   => '<-\ x?y 2',
  'x>=y?'   => '<-\ x?y 5',
  'x<y?'    => '<-\ x?y 3',
  'x>y?'    => '<-\ x?y 4',
  # G17
  'x=y?'    => '<-\ x?y 6',
  'x!=0?'   => '/-> x?0 1',
  'x<=0?'   => '/-> x?0 2',
  'x>=0?'   => '/-> x?0 5',
  'x<0?'    => '/-> x?0 3',
  'x>0?'    => '/-> x?0 4',
  'x=0?'    => '/-> x?0 6',
  'XOR'     => '<-\ LOGIC 2',
  # G18
  'xiy'     => '<-\ DISPLAY 9',
  'x+yi'    => '<-\ DISPLAY . 1',
  '\=y'     => '<-\ \=x,\=y 2',
  '\^y'     => '<-\ L.R. 2',
};

# Codepage 437
my $eqn_sequences = {
  # 0..31
  ' ' => '/-> SPACE',
  '!' => '/-> !',
  '"' => '',
  '#' => '',
  '$' => '',
  '%' => '/-> % rhd rhd <= <= <=',
  '&' => '',
  "'" => '',
  '(' => '() <=',
  ')' => '() lhd <= rhd',
  # '*' => '*',
  # '+' => '+',
  ',' => '<-\ ,',
  # '-' => '-',
  # '.' => '.',
  # '/' => '/',
  # '0' => '0',
  # '1' => '1',
  # '2' => '2',
  # '3' => '3',
  # '4' => '4',
  # '5' => '5',
  # '6' => '6',
  # '7' => '7',
  # '8' => '8',
  # '9' => '9',
  ':' => '',
  ';' => '',
  # '<' => '<',
  '=' => '<-\ =',
  # '>' => '>',
  '?' => '',
  '@' => '',
  'A' => 'RCL A',
  'B' => 'RCL B',
  'C' => 'RCL C',
  'D' => 'RCL D',
  'E' => 'RCL E',
  'F' => 'RCL F',
  'G' => 'RCL G',
  'H' => 'RCL H',
  'I' => 'RCL I',
  'J' => 'RCL J',
  'K' => 'RCL K',
  'L' => 'RCL L',
  'M' => 'RCL M',
  'N' => 'RCL N',
  'O' => 'RCL O',
  'P' => 'RCL P',
  'Q' => 'RCL Q',
  'R' => 'RCL R',
  'S' => 'RCL S',
  'T' => 'RCL T',
  'U' => 'RCL U',
  'V' => 'RCL V',
  'W' => 'RCL W',
  'X' => 'RCL X',
  'Y' => 'RCL Y',
  'Z' => 'RCL Z',
  '[' => '<-\ [] <=',
  ']' => '<-\ [] lhd <= rhd',
  '^' => 'y^x',
  '_' => '',
  '`' => '',
  # 'a' => 'a',                           # alpha
  'b' => '/-> BASE 8',
  'c' => '',
  'd' => '/-> BASE 5',
  # 'e' => 'e',
  'f' => '',
  'g' => '',
  'h' => '/-> BASE 6',
  # 'i' => 'i',                           # iscr
  'j' => '',
  'k' => '',
  'l' => '',
  'm' => '<-\ L.R. 4',
  'n' => '/-> SUMS 1',
  'o' => '/-> BASE 7',
  # 'p' => 'p',                           # pi
  'q' => '',
  'r' => '<-\ L.R. 3',
  's' => '/-> S,z 1 <=',
  # 't' => 't',                           # theta
  'u' => '<-\ CONST vee vee vee 3',
  'v' => '',
  'w' => '/-> \=x,\=y 3 lhd <= rhd',
  'x' => '/-> S,z 1 lhd <= rhd',
  'y' => '/-> S,z 2 lhd <= rhd',
  # 'z' => '',
  '{' => '',
  '|' => '',
  '}' => '',
  '~' => '+/-',
  # 127..166
  'a' => '<-\ CONST wedge wedge 4 <= <=', # 166
  # 167..226
  'p' => '<-\ pi',                        # 227
  # 228
  'z' => '/-> S,z 3 <=',                  # 229
  'µ' => '<-\ CONST vee vee vee 4 <=',    # 230
  # 231..232
  't' => '/-> t',                         # 233
  # 234..247
  '°' => '<-\ ->°F <= <= <= lhd <= rhd',  # 248
  # 249..252
  '²' => '/-> SUM 4 lhd <= <= rhd',       # 253
  # 254..255
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
      $out .= sprintf_number_statement( $statement );
    }
    elsif ($entry->{type} eq 'instruction') {
      my $mnemonic = $statement;
      # instructions without an operand
      if ( grep { $_ eq $mnemonic } @instructions ) {
        $out .= sprintf_single_instruction( $mnemonic );
      }
      # instructions with an address: GTO and XEQ
      elsif ( grep { $_ eq $mnemonic } @with_address ) {
        # absolute address
        if ( defined $entry->{address} ) {
          $out .= sprintf_address_instruction( $mnemonic, $entry->{address} );
        }
        # address label
        elsif ( defined $entry->{label} ) {
          $out .= sprintf_label_instruction( $mnemonic, $entry->{label}, $seq, $line );
        }
        # unknown operand
        else {
          print STDERR "Warn: missing type 'address' or 'label' in instruction '$mnemonic'\n";
          next;
        }
      }
      # instructions with a variable: LBL, INPUT, VIEW, STO, ...
      elsif ( grep { $_ eq $mnemonic } @with_variables, @with_indirects ) {
        $out .= sprintf_variable_instruction( $mnemonic, $entry->{variable} );
      }
      # instructions with a number: CF, FIX, ...
      elsif ( grep { $_ eq $mnemonic } @with_digits ) {
        $out .= sprintf_number_instruction( $mnemonic, $entry->{number} );
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
          $out .= sprintf_equation_instruction( $mnemonic, $entry->{equation} );
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
  # roll back for +/-
  my $reg = '\+'._divide.'-';
  $out =~ s/$reg/\+\/-/g;
  # roll back for 1/x
  $reg = '1'._divide.'x';
  $out =~ s/$reg/1\/x/g;
  # roll back for /c
  $reg = _divide.'c';
  $out =~ s/$reg/\/c/g;
  # roll back for R/S
  $reg = 'R'._divide.'S';
  $out =~ s/$reg/R\/S/g;
  # correct /->
  $reg = _divide._rarr;
  $_ = _rsh;
  $out =~ s/$reg/$_/g;
  # correct <-\
  $reg = _larr.'\\\\';
  $_ = _lsh;
  $out =~ s/$reg/$_/g;
  binmode(STDOUT, ":utf8");
}

print STDOUT $out;


###############################
# Here are the subs 

# number statement
sub sprintf_number_statement {
  my $number = shift;
  my $keysequence = '';

  defined $shortcut and
    $keysequence = sprintf("\t\t; %d ENTER", $number);
  return sprintf("%s%03d\t%s%s\n", $lbl, ++$loc, $number, $keysequence);
}

# instructions without an operand
sub sprintf_single_instruction {
  my $mnemonic = shift;
  my $keysequence = '';

  defined $shortcut and
    $keysequence = sprintf("\t\t; %s", $sequences->{$mnemonic} ? $sequences->{$mnemonic} : $mnemonic);
  return sprintf("%s%03d\t%s%s\n", $lbl, ++$loc, $mnemonic, $keysequence);
}

# instructions with absolute address
sub sprintf_address_instruction {
  my $mnemonic = shift;
  my $addr = shift;
  my $keysequence = '';

  defined $shortcut and
    $keysequence = sprintf("\t; %s %s", $sequences->{$mnemonic} ? $sequences->{$mnemonic} : $mnemonic, $addr);
  return sprintf("%s%03d\t%s %s%s\n", $lbl, ++$loc, $mnemonic, $addr, $keysequence);
}

# instructions with address label
sub sprintf_label_instruction {
  my $mnemonic = shift;
  my $label = shift;
  my $seq = shift;
  my $line = shift;
  my $keysequence = '';
  
  defined $response->{labels}->{$label}->{segment} or
    print STDERR "Warn: missing 'label' for instruction '$mnemonic'\n" and next;

  if ( $response->{labels}->{$label}->{segment} eq $seq ) {
    my $near = $response->{labels}->{$label}->{statement} + $line - $loc + 1;
    my $digits = join(' ', split(//, sprintf("%03d", $near)));
    defined $shortcut and
      $keysequence = sprintf("\t; %s %s %s", $sequences->{$mnemonic} ? $sequences->{$mnemonic} : $mnemonic, $lbl, $digits);
    return sprintf("%s%03d\t%s %s%03d%s\n", $lbl, ++$loc, $mnemonic, $lbl, $near, $keysequence);
  }
  else {
    print STDERR "Warn: far 'label' not supported yet\n";
    my $far = $response->{labels}->{$label}->{segment};
    my $near = $response->{labels}->{$label}->{statement} + 1;
    defined $shortcut and
      $keysequence = sprintf("\t; %s ...", $sequences->{$mnemonic} ? $sequences->{$mnemonic} : $mnemonic);
    return sprintf("%s%03d\t%s %s+%03d%s\n", $lbl, ++$loc, $mnemonic, $far, $near, $keysequence);
  }
}

# instructions with a variable
sub sprintf_variable_instruction {
  my $mnemonic = shift;
  my $variable = shift;
  my $keysequence = '';

  defined $variable or
    print STDERR "Warn: missing type 'variable' in instruction '$mnemonic'\n" and next;

  if ($mnemonic =~ /LBL/) {
    # set line number if instruction is 'LBL'
    $lbl = $variable;
    $loc = 0;
  }
  my $space = $variable =~ /\([IJ]\)/ ? '' : ' ';   # indirects have no space
  defined $shortcut and
    $keysequence = sprintf("\t\t; %s %s", $sequences->{$mnemonic} ? $sequences->{$mnemonic} : $mnemonic, $variable);
  return sprintf("%s%03d\t%s%s%s%s\n", $lbl, ++$loc, $mnemonic, $space, $variable, $keysequence);
}

sub sprintf_number_instruction {
  my $mnemonic = shift;
  my $number = shift;
  my $keysequence = '';

  defined $number or
    print STDERR "Warn: missing type 'number' in instruction '$mnemonic'\n" and next;

  my $digits = $number < 10 ? $number : sprintf(". %d", $number % 10);
  defined $shortcut and
    $keysequence = sprintf("\t\t; %s %s", $sequences->{$mnemonic} ? $sequences->{$mnemonic} : $mnemonic, $digits);
  return sprintf("%s%03d\t%s %s%s\n", $lbl, ++$loc, $mnemonic, $number, $keysequence);
}

sub sprintf_equation_instruction {
  my $mnemonic = shift;
  my $definition = shift;
  my $keysequence = '';
  my $ret = '';

  defined $equations->{$definition} or
    print STDERR "Warn: missing 'equation' for instruction '$mnemonic'\n" and next;

  my $equation = $equations->{$definition};
  if ($shortcut) {
    foreach (split //, $equation) {
      $keysequence .= sprintf(" %s", $eqn_sequences->{$_} ? $eqn_sequences->{$_} : $_);
    }
    # '() <= RCL I () lhd <= rhd'  'RCL (I)'
    $keysequence =~ s/\(\) <= RCL I \(\) lhd <= rhd/RCL 0/g;
    # '() <= RCL J () lhd <= rhd'  'RCL (J)'
    $keysequence =~ s/\(\) <= RCL J \(\) lhd <= rhd/RCL \./g;
    # '\ >'  'STO SC'
    $keysequence =~ s/\\ >/STO CAN/g;
    # '- >'  ' /-> 2 rsh <= <= <='
    $keysequence =~ s/ \- \>/ \/-> 2 rhd <= <= <=/g;
    $ret = sprintf(";%s\n", $keysequence);
  }
  $ret .= sprintf("%s%03d\t%s\n", $lbl, ++$loc, $equation);
  return $ret;
}

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
  -u, --unicode       Output as Unicode (UTF-8)
  -s, --shortcut      Output shortcut keys as comment
  --debug             Show debug information on STDERR

  --file=<asm-file>:
    Location of asm-file (Default is STDIN)

This script converts an assembler program to HP35s native program code
The output will be sent to STDOUT

USE
  exit 0;
};
