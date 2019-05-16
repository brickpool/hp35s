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
#   2019-05-14: adding trigraphs to key sequences
#   2019-05-15: output can be trigraph, ascii-text or unicode
#   2019-05-16: correct handling of numbers

use strict;
use warnings;

use Getopt::Long;
use Parser::HPC qw(@instructions @with_address @with_digits @with_variables @with_indirects @expressions @functions);
use Data::Dumper;

# Declaration
my $VERSION = '0.3.3';
my $version;
my $ascii;
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
  "ascii"     => \$ascii,   "a"   => \$ascii,
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
use constant _bksp    => "\N{U+21E6}";
use constant _int     => "\N{U+222B}";
use constant _ymacr   => "\N{U+0233}";
use constant _supx    => "\N{U+02E3}";
use constant _circ    => "\N{U+0302}";
use constant _Sigma   => "\N{U+03A3}";
use constant _Phi     => "\N{U+03A6}";
use constant _alpha   => "\N{U+03B1}";
use constant _gamma   => "\N{U+03B3}";
use constant _epsilon => "\N{U+03B5}";
use constant _theta   => "\N{U+03B8}";
use constant _lambda  => "\N{U+03BB}";
use constant _pi      => "\N{U+03C0}";
use constant _sigma   => "\N{U+03C3}";
use constant _larr    => "\N{U+2190}";
use constant _uarr    => "\N{U+2191}";
use constant _rarr    => "\N{U+2192}";
use constant _darr    => "\N{U+2193}";
use constant _sqrt    => "\N{U+221A}";
use constant _infin   => "\N{U+221E}";
use constant _wedge   => "\N{U+2227}";
use constant _vee     => "\N{U+2228}";
use constant _neq     => "\N{U+2260}";
use constant _leq     => "\N{U+2264}";
use constant _geq     => "\N{U+2265}";
use constant _brtri   => "\N{U+25B6}";
use constant _cancel  => "\N{U+1D402}";
use constant _iscr    => "\N{U+1D4BE}";

# HP Trigraphs
my $trigraphs = {
  # G1
  '*'     => '\.x',
  '/'     => '\:-',
  # G2
  '10^x'  => '10\^x',
  'pi'    => '\pi',
  'Z+'    => '\GS+',
  'Z-'    => '\GS-',
  # G3
  'Zx'    => '\GSx',
  'Zx^2'  => '\GSx\^2',
  'Zxy'   => '\GSxy',
  'Zy'    => '\GSy',
  'Zy^2'  => '\GSy\^2',
  'S,z'   => 'S,\Gs',
  'zx'    => '\Gsx',
  'zy'    => '\Gsy',
  '$FN_d' => '\.SFN d',
  # G5
  '->°C'  => '\->\^oC',
  # G6
  'CLZ'   => 'CL\GS',
  '->CM'  => '\->CM',
  '->DEG' => '\->DEG',
  # G7
  '<-ENG' => '\<-ENG',
  'ENG->' => 'ENG\->',
  'e^x'   => 'e\^x',
  # G8
  '->°F'  => '\->\^oF',
  '->GAL' => '\->GAL',
  # G9
  '->HMS' => '\->HMS',
  'HMS->' => 'HMS\->',
  '->IN'  => '\->IN',
  'INT/'  => 'INT\:-',
  # G10
  '->KG'  => '\->KG',
  '->KM'  => '\->KM',
  '->L'   => '\->L',
  '->LB'  => '\->LB',
  # G11
  '->MILE'=> '\->MILE',
  # G12
  'rta'   => 'r\Gha',
  '->RAD' => '\->RAD',
  'RCL*'  => 'RCL\.x',
  'RCL/'  => 'RCL\:-',
  # G13
  'Rv'    => 'R\|v',
  'R^'    => 'R\|^',
  # G14
  'STO*'  => 'STO\.x',
  'STO/'  => 'STO\:-',
  # G15
  'sx'    => '\Gsx',
  'sy'    => '\Gsy',
  'x^2'   => 'x\^2',
  'sqrt'  => '\v/x',
  'xroot' => 'x\v/y',
  # G16
  '\x-w'  => '\x-w',
  'x!=y?' => 'x\=/y?',
  'x<=y?' => 'x\<=y?',
  'x>=y?' => 'x\>=y?',
  # G17
  'x!=0?' => 'x\=/0?',
  'x<=0?' => 'x\<=0?',
  'x>=0?' => 'x\>=0?',
  # G18
  'xiy'   => 'x\Miy',
#  'x+yi'  => 'x+y\Mi', only mode ALG
  'y^x'   => 'y\^x',
};

# Key sequences
my $sequences = {
  # G2
  '10\^x'   => '\+> 10\^x',
  '%'       => '\+> %',
  '%CHG'    => '\<+ %CHG',
  '\pi'     => '\<+ \pi',
  '\GS-'    => '\<+ \GS-',
  # G3
  '\GSx'    => '\+> SUMS 2',
  '\GSx\^2' => '\+> SUMS 4',
  '\GSxy'   => '\+> SUMS 6',
  '\GSy'    => '\+> SUMS 3',
  '\GSy\^2' => '\+> SUMS 4',
  '\Gsx'    => '\+> S,\Gs 3',
  '\Gsy'    => '\+> S,\Gs 4',
  '\.SFN d' => '\<+ \.S',
  # G4
  'ABS'     => '\+> ABS',
  'ACOS'    => '\+> ACOS',
  'ACOSH'   => '\<+ HYP \+> ACOS',
  'ALG'     => 'MODE 4',
  'ALOG'    => '\+> 10\^x',
  'ALL'     => '\<+ DISPLAY 4',
  'AND'     => '\<+ LOGIC 1',
  'ARG'     => '\<+ ARG',
  'ASIN'    => '\+> ASIN',
  'ASINH'   => '\<+ HYP \+> ASIN',
  'ATAN'    => '\+> ATAN',
  # G5
  'ATANH'   => '\<+ HYP \+> ATAN',
  'b'       => '\<+ L.R. 5',
  'BIN'     => '\+> BASE 4',
  '/c'      => '\<+ /c',
  '\->\^oC' => '\+> \->\^oC',
  'CF'      => '\<+ FLAGS 2',
  # G6
  'CLZ'     => '\+> CLEAR 4',
  'CLVARS'  => '\+> CLEAR 2',
  'CLx'     => '\+> CLEAR 1',
  'CLSTK'   => '\+> CLEAR 5',
  '\->CM'   => '\+> \->cm',
  'nCr'     => '\<+ nCr',
  'COSH'    => '\<+ HYP COS',
  'DEC'     => '\+> BASE 1',
  'DEG'     => 'MODE 1',
  '\->DEG'  => '\+> \->DEG',
  # G7
  'DSE'     => '\+> DSE',
  'ENG'     => '\<+ DISPLAY 3',
  'e\^x'    => '\+> e\^x',
  # G8
  'EXP'     => '\+> e\^x',
  '\->\^oF' => '\<+ \->\^oF',
  'FIX'     => '\<+ DISPLAY 1',
  'FN='     => '\<+ FN=',
  'FP'      => '\<+ INTG 5',
  'FS?'     => '\<+ FLAGS 3',
  '\->GAL'  => '\<+ \->gal',
  'GRAD'    => 'MODE 3',
  'HEX'     => '\+> BASE 2',
  # G9
  '\->HMS'  => '\+> \->HMS',
  'HMS\->'  => '\<+ HMS\->',
  '\->IN'   => '\+> \->in',
  'IDIV'    => '\<+ INTG 2',
  'INT\:-'  => '\<+ INTG 2',
  'INTG'    => '\<+ INTG 4',
  'INPUT'   => '\<+ INPUT',
  'INV'     => '1/x',
  # G10
  'IP'      => '\<+ INTG 6',
  'ISG'     => '\<+ ISG',
  '\->KG'   => '\+> \->kg',
  '\->KM'   => '\+> \->KM',
  '\->L'    => '\+> \->l',
  'LASTx'   => '\+> LASTx',
  '\->LB'   => '\+> \->lb',
  'LBL'     => '\+> LBL',
  'LN'      => '\+> LN',
  'LOG'     => '\<+ LOG',
  'm'       => '\<+ L.R. 4',
  # G11
  '\->MILE' => '\+> \->MILE',
  'n'       => '\+> SUMS 1',
  'NAND'    => '\<+ LOGIC 5',
  'NOR'     => '\<+ LOGIC 6',
  'NOT'     => '\<+ LOGIC 4',
  'OCT'     => '\+> BASE 3',
  'OR'      => '\<+ LOGIC 3',
  'nPr'     => '\+> nPr',
  'PSE'     => '\+> PSE',
  # G12
  'r'       => '\<+ L.R. 3',
  'r\Gha'   => '\<+ DISPLAY . 0',
  'RAD'     => 'MODE 1',
  '\->RAD'  => '\<+ \->RAD',
  'RADIX,'  => '\<+ DISPLAY 6',
  'RADIX.'  => '\<+ DISPLAY 5',
  'RADOM'   => '\+> RADOM',
  'RCL+'    => 'RCL +',
  'RCL-'    => 'RCL -',
  'RCL\.x'  => 'RCL \.x',
  'RCL\:-'  => 'RCL \:-',
  'RMDR'    => '\<+ INTG 3',
  # G13
  'RND'     => '\<+ RND',
  'RPN'     => 'MODE 5',
  'RTN'     => '\<+ RTN',
  'R\|^'    => '\+> R\|^',
  'SCI'     => '\<+ DISPLAY 2',
  'SEED'    => '\<+ SEED',
  'SF'      => '\<+ FLAGS 1',
  'SGN'     => '\<+ INTG 1',
  # G14
  'SINH'    => '\<+ HYP SIN',
  'SQ'      => '\+> x\^2',
  'SQRT'    => '\v/x',
  'STO'     => '\+> STO',
  'STO+'    => '\+> STO +',
  'STO-'    => '\+> STO -',
  'STO\.x'  => '\+> STO \.x',
  'STO\:-'  => '\+> STO \:-',
  'STOP'    => 'R/S',
  # G15
  '\Gsx'    => '\+> S,\Gs 1',
  '\Gsy'    => '\+> S,\Gs 2',
  'TANH'    => '\<+ HYP TAN',
  'VIEW'    => '\<+ VIEW',
  'x\^2'    => '\+> x\^2',
  'x\v/y'   => '\<+ x\v/y',
  '\x-'     => '\<+ \x-,\y- 1',
  '\x^'     => '\<+ L.R. 1',
  '!'       => '\+> !',
  # G16
  'XROOT'   => '\<+ x\v/y',
  '\x-w'    => '\<+ \x-,\y- 3',
  'x<>'     => '\<+ x<>y',
  'x\=/y?'  => '\<+ x?y 1',
  'x\<=y?'  => '\<+ x?y 2',
  'x\>=y?'  => '\<+ x?y 5',
  'x<y?'    => '\<+ x?y 3',
  'x>y?'    => '\<+ x?y 4',
  # G17
  'x=y?'    => '\<+ x?y 6',
  'x\=/0?'  => '\+> x?0 1',
  'x\<=0?'  => '\+> x?0 2',
  'x\>=0?'  => '\+> x?0 5',
  'x<0?'    => '\+> x?0 3',
  'x>0?'    => '\+> x?0 4',
  'x=0?'    => '\+> x?0 6',
  'XOR'     => '\<+ LOGIC 2',
  # G18
  'x\Miy'   => '\<+ DISPLAY 9',
#  'x+y\Mi'  => '\<+ DISPLAY . 1',  only mode ALG
  '\y-'     => '\<+ \x-,\y- 2',
  '\y^'     => '\<+ L.R. 2',
};

# number sequences
my $numbers = {
  'dec' => '\CC \+> BASE 1 \+> PRGM',
  'hex' => '\CC \+> BASE 2 \+> PRGM',
  'oct' => '\CC \+> BASE 3 \+> PRGM',
  'bin' => '\CC \+> BASE 4 \+> PRGM',
  'd'   => '\+> BASE 5',
  'h'   => '\+> BASE 6',
  'o'   => '\+> BASE 7',
  'b'   => '\+> BASE 8',
  '0'   => '0',
  '1'   => '1',
  '2'   => '2',
  '3'   => '3',
  '4'   => '4',
  '5'   => '5',
  '6'   => '6',
  '7'   => '7',
  '8'   => '8',
  '9'   => '9',
  'A'   => 'SIN',
  'B'   => 'COS',
  'C'   => 'TAN',
  'D'   => '\v/x',
  'E'   => 'y^x',
  'F'   => '1/x',
  'e'   => 'E',
  '-'   => '+/-',
  '.'   => '.',
};

# EQN character
my $character = {
  # 0..31
  ' ' => '\+> SPACE',
  '!' => '\+> !',
  '"' => '',
  '#' => '',
  '$' => '',
  '%' => '\+> % \.> \.> \BS \BS \BS',
  '&' => '',
  "'" => '',
  '(' => '() \BS',
  ')' => '() \<. \BS \.>',
  # '*' => '*',
  # '+' => '+',
  ',' => '\<+ ,',
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
  '=' => '\<+ =',
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
  '[' => '\<+ [] \BS',
  '\\' => '',
  ']' => '\<+ [] \<. \BS \.>',
  '^' => 'y^x',
  '_' => '',
  '`' => '',
  'a' => '\<+ CONST \.^ \.^ 4 \BS \BS',
  'b' => '\+> BASE 8',
  'c' => '',
  'd' => '\+> BASE 5',
  'e' => 'E',
  'f' => '',
  'g' => '',
  'h' => '\+> BASE 6',
  'i' => '\Mi',
  'j' => '',
  'k' => '',
  'l' => '',
  'm' => '\<+ L.R. 4',
  'n' => '\+> SUMS 1',
  'o' => '\+> BASE 7',
  'p' => '',
  'q' => '',
  'r' => '\<+ L.R. 3',
  's' => '\+> S,\Gs 1 \BS',
  't' => '',
  'u' => '\<+ CONST \.v \.v \.v 3',
  'v' => '',
  'w' => '\+> \x-,\y- 3 \<. \BS \.>',
  'x' => '\+> S,\Gs 1 \<. \BS \.>',
  'y' => '\+> S,\Gs 2 \<. \BS \.>',
  'z' => '',
  '{' => '',
  '|' => '',
  '}' => '',
  '~' => '',
  # 127
  '\<)' => '',
  '\x-' => '\<+ \x-,\y- 1',
  '\.V' => '',
  '\v/' => '',
  '\.S' => '',
  '\GS' => '\+> SUM 2 \BS',
  '\|>' => 'STO \CC',
  '\pi' => '\<+ \pi',
  '\.d' => '',
  '\<=' => '',
  '\>=' => '',
  '\=/' => '',
  '\Ga' => '\<+ CONST \.^ \.^ 1',
  '\->' => '\+> \->l \<. \BS \BS \BS',
  '\<-' => '',
  '\|v' => '',
  '\|^' => '',
  '\Gg' => '\<+ CONST \.^ \.^ 5 \BS',
  '\Ge' => '\<+ CONST \.v \.v 6 \BS ',
  '\Gn' => '',
  '\Gh' => '\+> \Gh',
  '\Gl' => '\<+ CONST \.^ \.^ \.^ 2 \BS',
  '\Gr' => '',
  '\Gs' => '\+> S,\Gs 3 \BS',
  '\Gt' => '',
  '\Gw' => '',
  '\GD' => '',
  '\PI' => '',
  '\GW' => '',
  '\[]' => '',
  '\oo' => '\<+ CONST 6 \.< \BS \.>',
  # 160..170
  '\<<' => '',
  # 172..175
  '°' => '\<+ ->\^oF \.> \BS \BS \BS \<. \BS \.>',
  '\^o' => '\<+ ->\^oF \.> \BS \BS \BS \<. \BS \.>',
  # 177
  '²'   => '\+> SUM 4 \<. \BS \BS \.>',
  '\^2' => '\+> SUM 4 \<. \BS \BS \.>',
  # 179..180
  'µ'   => '\<+ CONST \.v \.v \.v 4 \BS',
  '\Gm' => '\<+ CONST \.v \.v \.v 4 \BS',
  # 182..186
  '\>>' => '',
  # 188..214
  # '\.x' => '\.x',
  '\O/' => '\<+ CONST \.v \.v 4 \BS',
  # 217..222
  '\Gb' => '',
  # 224..246
  # '\:-' => '\:-',
  # 248..255
  # additional trigraphs
  '\h-' => '\<+ CONST \.v \.v 3',
  # '\Mi' => '\Mi',
  '\x^' => '\<+ L.R. 1 \.> \BS \BS',
  '\y^' => '\<+ L.R. 2 \.> \BS \BS',
  '\y-' => '\<+ \x-,\y- 2',
};

# ASCII mapping
my $plaintext = {
  '\BS'   => 'bksp',
  '\CC'   => 'cancel',
  '\x-'   => 'xbar',
  '\v/x'  => 'sqrt',
  'x\v/y' => 'xroot',
  '\.S'   => '$',
  '\GS'   => 'Z',
  '\|>'   => '>',
  '\pi'   => 'pi',
  '\<='   => '<=',
  '\>='   => '>=',
  '\=/'   => '!=',
  '\Ga'   => 'alpha',
  '\->'   => '->',
  '\<-'   => '<-',
  '\|v'   => 'v',
  '\|^'   => '^',
  '\Gg'   => 'gamma',
  '\Ge'   => 'epsilon',
  '\Gh'   => 't',
  '\Gl'   => 'lambda',
  '\Gs'   => 'z',
  '\oo'   => 'infty',
  '\^o'   => '^o',
  '\Gm'   => 'mu',
  '\^2'   => '^2',
  '\.x'   => '*',
  '\O/'   => 'Phi',
  '\:-'   => '/',
  '\<.'   => 'left',
  '\.>'   => 'right',
  '\.v'   => 'down',
  '\.^'   => 'up',
  '\<+'   => 'ctrl',
  '\+>'   => 'shift',
  '\h-'   => 'hbar',
  '\Mi'   => 'i',
  '\^x'   => '^x',
  '\x^'   => 'xcirc',
  '\y^'   => 'ycirc',
  '\y-'   => 'ybar',
};

# Unicode mapping
my $unicodes = {
  '\BS'   => _bksp,
  '\CC'   => _cancel,
  '\x-'   => 'x'._macr,
  '\v/'   => _sqrt,
  '\.S'   => _int,
  '\GS'   => _Sigma,
  '\|>'   => _brtri,
  '\pi'   => _pi,
  '\<='   => _leq,
  '\>='   => _geq,
  '\=/'   => _neq,
  '\Ga'   => _alpha,
  '\->'   => _rarr,
  '\<-'   => _larr,
  '\|v'   => _darr,
  '\|^'   => _uarr,
  '\Gg'   => _gamma,
  '\Ge'   => _epsilon,
  '\Gh'   => _theta,
  '\Gl'   => _lambda,
  '\Gs'   => _sigma,
  '\oo'   => _infin,
  '\^o'   => '°',
  '\Gm'   => 'µ',
  '\^2'   => _sup2,
  '\.x'   => _times,
  '\O/'   => _Phi,
  '\:-'   => _divide,
  '\<.'   => '<',
  '\.>'   => '>',
  '\.v'   => _vee,
  '\.^'   => _wedge,
  '\<+'   => _lsh,
  '\+>'   => _rsh,
  '\h-'   => 'h'._macr,
  '\Mi'   => _iscr,
  '\^x'   => _supx,
  '\x^'   => 'x'._circ,
  '\y^'   => _ycirc,
  '\y-'   => _ymacr,
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

    if ($entry->{type} =~ /decimal|binary|octal|hex/) {
      $out .= sprintf_number_statement( $statement );
    }
    elsif ($entry->{type} eq 'complex') {
      $out .= sprintf_complex_statement( $statement );
    }
    elsif ($entry->{type} eq 'instruction') {
      my $mnemonic = $statement;
      # instructions without an operand
      if ( grep { $_ eq $mnemonic } @instructions, @functions ) {
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
  binmode(STDOUT, ":utf8");
}
# option --ascii
elsif ($ascii) {
  foreach (keys %$plaintext) {
    my $a = quotemeta $_;
    my $b = $plaintext->{$_};
    $out =~ s/$a/$b/g;
  }
}
else {
  print STDOUT '%%HP: T(3)A(D)F(.);', "\n";
}

print STDOUT $out;


###############################
# Here are the subs 

# number statement
sub sprintf_number_statement {
  my $number = shift;
  my $keysequence = '';

  if ($shortcut) {
    my ($sign, $digits, $exponent, $base) = $number =~ /^(\-?)([\.\dA-F]+)(?:e(\-?[\.\dA-F]+))?([dhob]?)$/;

    # start sequence
    if ($base eq 'd') {
      $keysequence .= sprintf("\t\t; %s", $numbers->{'dec'});
    }
    elsif ($base eq 'h') {
      $keysequence .= sprintf("\t\t; %s", $numbers->{'hex'});
    }
    elsif ($base eq 'o') {
      $keysequence .= sprintf("\t\t; %s", $numbers->{'oct'});
    }
    elsif ($base eq 'b') {
      $keysequence .= sprintf("\t\t; %s", $numbers->{'bin'});
    }
    else {
      $keysequence = "\t\t;";
    }

    # sequence for mantissa and exponent
    foreach (split //, $digits) {
      exists $numbers->{$_} and
        $keysequence .= sprintf(" %s", $numbers->{$_} );
    }
    if ($sign) {
      $keysequence .= sprintf(" %s", $numbers->{'-'} );
    }
    if ($exponent) {
      $keysequence .= sprintf(" %s", $numbers->{'e'} );
      foreach (split //, $exponent) {
        exists $numbers->{$_} and
          $keysequence .= sprintf(" %s", $numbers->{$_} );
      }
    }

    # end sequence
    if ($base) {
      $keysequence .= sprintf(" %s", $numbers->{$base});
      $keysequence .= sprintf(" %s", $numbers->{'dec'});
    }
    $keysequence .= ' ENTER';
  }
  return sprintf("%s%03d\t%s%s\n", $lbl, ++$loc, $number, $keysequence);
}

# complex statement
sub sprintf_complex_statement {
  my $complex = shift;
  my $keysequence = '';

  my ($a, $sep, $b) = split /([it])/, $complex;
  defined $b or
    print STDERR "Warn: unknown syntax for complex number '$complex'\n" and next;

  $sep =~ s/i/\\Mi/;
  $sep =~ s/t/\\Gh/;
  my $seq = exists $sequences->{sep} ? $sequences->{sep} : $sep;

  defined $shortcut and
    $keysequence = sprintf("\t\t; %s %s %s ENTER", $a, $seq, $b);
  return sprintf("%s%03d\t%s%s%s%s\n", $lbl, ++$loc, $a, $sep, $b, $keysequence);
}

# instructions without an operand
sub sprintf_single_instruction {
  my $mnemonic = shift;
  my $keysequence = '';

  exists $trigraphs->{$mnemonic} and
    $mnemonic = $trigraphs->{$mnemonic};

  defined $shortcut and
    $keysequence = sprintf("\t\t; %s", exists $sequences->{$mnemonic} ? $sequences->{$mnemonic} : $mnemonic);

  return sprintf("%s%03d\t%s%s\n", $lbl, ++$loc, $mnemonic, $keysequence);
}

# instructions with absolute address
sub sprintf_address_instruction {
  my $mnemonic = shift;
  my $addr = shift;
  my $keysequence = '';

  exists $trigraphs->{$mnemonic} and
    $mnemonic = $trigraphs->{$mnemonic};

  defined $shortcut and
    $keysequence = sprintf("\t; %s %s", exists $sequences->{$mnemonic} ? $sequences->{$mnemonic} : $mnemonic, $addr);
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

  exists $trigraphs->{$mnemonic} and
    $mnemonic = $trigraphs->{$mnemonic};

  if ( $response->{labels}->{$label}->{segment} eq $seq ) {
    my $near = $response->{labels}->{$label}->{statement} + $line - $loc + 1;
    my $digits = join(' ', split(//, sprintf("%03d", $near)));
    defined $shortcut and
      $keysequence = sprintf("\t; %s %s %s", exists $sequences->{$mnemonic} ? $sequences->{$mnemonic} : $mnemonic, $lbl, $digits);
    return sprintf("%s%03d\t%s %s%03d%s\n", $lbl, ++$loc, $mnemonic, $lbl, $near, $keysequence);
  }
  else {
    print STDERR "Warn: far 'label' not supported yet\n";
    my $far = $response->{labels}->{$label}->{segment};
    my $near = $response->{labels}->{$label}->{statement} + 1;
    defined $shortcut and
      $keysequence = sprintf("\t; %s ...", exists $sequences->{$mnemonic} ? $sequences->{$mnemonic} : $mnemonic);
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

  exists $trigraphs->{$mnemonic} and
    $mnemonic = $trigraphs->{$mnemonic};

  if ($mnemonic =~ /LBL/) {
    # set line number if instruction is 'LBL'
    $lbl = $variable;
    $loc = 0;
  }
  my $space = $variable =~ /\([IJ]\)/ ? '' : ' ';   # indirects have no space
  defined $shortcut and
    $keysequence = sprintf("\t\t; %s %s", exists $sequences->{$mnemonic} ? $sequences->{$mnemonic} : $mnemonic, $variable);
  return sprintf("%s%03d\t%s%s%s%s\n", $lbl, ++$loc, $mnemonic, $space, $variable, $keysequence);
}

sub sprintf_number_instruction {
  my $mnemonic = shift;
  my $number = shift;
  my $keysequence = '';

  defined $number or
    print STDERR "Warn: missing type 'number' in instruction '$mnemonic'\n" and next;

  exists $trigraphs->{$mnemonic} and
    $mnemonic = $trigraphs->{$mnemonic};

  my $digits = $number < 10 ? $number : sprintf(". %d", $number % 10);
  defined $shortcut and
    $keysequence = sprintf("\t\t; %s %s", exists $sequences->{$mnemonic} ? $sequences->{$mnemonic} : $mnemonic, $digits);
  return sprintf("%s%03d\t%s %s%s\n", $lbl, ++$loc, $mnemonic, $number, $keysequence);
}

sub sprintf_equation_instruction {
  my $mnemonic = shift;
  my $definition = shift;
  my $keysequence = '';
  my $ret = '';

  defined $equations->{$definition} or
    print STDERR "Warn: missing 'equation' for instruction '$mnemonic'\n" and next;

  exists $trigraphs->{$mnemonic} and
    $mnemonic = $trigraphs->{$mnemonic};

  my $equation = $equations->{$definition};
  if ($shortcut) {
    my $trigraph = '';
    foreach (split //, $equation) {
      if (/\\/ and length $trigraph == 0) {
        $trigraph = '\\';
        next;
      }
      elsif (/\\/ and $trigraph =~ /\\/) {
        $_ = '\\';
        $trigraph = '';
      }
      elsif (length $trigraph > 0 and length $trigraph < 3) {
        $trigraph .= $_;
        next if length $trigraph < 3;
      }
      if (length $trigraph >= 3) {
        $_ = $trigraph;
        $trigraph = '';
      }
      my $seq = exists $character->{$_} ? $character->{$_} : $_;
      if (length $seq > 0) {
        $keysequence .= sprintf(" %s", $seq);
      }
    }

    # 'RCL (I)'
    my $regex = quotemeta '() \BS RCL I () \<. \BS \.>';
    my $repl  = 'RCL 0';
    $keysequence =~ s/$regex/$repl/g;

    # 'RCL (J)'
    $regex = quotemeta '() \BS RCL J () \<. \BS \.>';
    $repl  = 'RCL .';
    $keysequence =~ s/$regex/$repl/g;

    $ret = sprintf("; EQN%s ENTER\n", $keysequence);
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
  -a, --ascii         Output as ASCII (7-bit)
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
