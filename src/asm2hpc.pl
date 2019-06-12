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
#   http://github.com/brickpool/hp35s/CHANGELOG.md

use strict;
use warnings;

use Getopt::Long;
use Parser::HPC qw(@instructions @with_address @with_digits @with_variables @with_indirects @expressions @functions @register);
use Data::Dumper;

# Declaration
my $VERSION = '0.3.6';
my $version;
my $jumpmark;
my $plain;
my $unicode;
my $markdown;
my $shortcut;
my $help;
my $debug;
my $file;
# the next line is only for perl debugging
#$file = 'test.asm';

Getopt::Long::Configure('bundling');
GetOptions (
  "help"      => \$help,      "h"   => \$help,
  "version"   => \$version,   "v"   => \$version,
  "jumpmark"  => \$jumpmark,  "j"   => \$jumpmark,
  "plain"     => \$plain,     "p"   => \$plain,
  "markdown"  => \$markdown,  "m"   => \$markdown,
  "unicode"   => \$unicode,   "u"   => \$unicode,
  "shortcut"  => \$shortcut,  "s"   => \$shortcut,
  "debug"                           => \$debug,
  "file=s"    => \$file,      "f=s" => \$file,
);
# Check command line arguments
&version()    if $version;
&help()       if $help;
$debug        = 0 unless defined $debug;

my $parser = Parser::HPC->new;

# unicode eqn charset
use constant _supc      => "\N{U+1D9C}";
use constant _supe      => "\N{U+1D49}";
use constant _supg      => "\N{U+1D4D}";
use constant _suph      => "\N{U+02B0}";
use constant _supm      => "\N{U+1D50}";
use constant _supn      => "\N{U+207F}";
use constant _supp      => "\N{U+1D56}";
use constant _supr      => "\N{U+02B3}";
use constant _supt      => "\N{U+1D57}";
use constant _capA      => "\N{U+1D00}";
use constant _copf      => "\N{U+1D554}";
use constant _Fopf      => "\N{U+1D53D}";
use constant _Gopf      => "\N{U+1D53E}";
use constant _supk      => "\N{U+1D4F}";
use constant _Ropf      => "\N{U+211D}";
use constant _supo      => "\N{U+1D52}";
use constant _hbar      => "\N{U+210F}";
use constant _topf      => "\N{U+1D565}";
use constant _alpha     => "\N{U+03B1}";
use constant _lambda    => "\N{U+03BB}";
use constant _Phi       => "\N{U+03A6}";
use constant _gamma     => "\N{U+03B3}";
use constant _infin     => "\N{U+221E}";
use constant _epsilon   => "\N{U+03B5}";
use constant _supminus  => "\N{U+207B}";
use constant _divide    => "\N{U+00F7}";
use constant _times     => "\N{U+00D7}";
use constant _Sigma     => "\N{U+03A3}";
use constant _pi        => "\N{U+03C0}";
use constant _rarr      => "\N{U+2192}";
use constant _sup2      => "\N{U+00B2}";
use constant _theta     => "\N{U+03B8}";
use constant _supalpha  => "\N{U+1D45}";
use constant _sigma     => "\N{U+03C3}";
use constant _macr      => "\N{U+0304}";
use constant _circ      => "\N{U+0302}";
use constant _ycirc     => "\N{U+0177}";
use constant _ymacr     => "\N{U+0233}";
use constant _sup1      => "\N{U+00B9}";
use constant _supB      => "\N{U+1D2E}";
use constant _capC      => "\N{U+1D04}";
use constant _supG      => "\N{U+1D33}";
use constant _supN      => "\N{U+1D3A}";
use constant _supa      => "\N{U+1D43}";
use constant _supu      => "\N{U+1D58}";
use constant _capE      => "\N{U+1D07}";
use constant _iscr      => "\N{U+1D4BE}";
use constant _supR      => "\N{U+1D3F}";
use constant _supV      => "\N{U+2C7D}";
use constant _capZ      => "\N{U+1D22}";
use constant _brtri     => "\N{U+25BA}";
# unicode non eqn charset
use constant _sqrt      => "\N{U+221A}";
use constant _int       => "\N{U+222B}";
use constant _leq       => "\N{U+2264}";
use constant _geq       => "\N{U+2265}";
use constant _neq       => "\N{U+2260}";
use constant _larr      => "\N{U+2190}";
use constant _darr      => "\N{U+2193}";
use constant _uarr      => "\N{U+2191}";
use constant _supx      => "\N{U+02E3}";
# unicode extra
use constant _bksp      => "\N{U+21E6}";
use constant _cancel    => "\N{U+1F132}";
use constant _vee       => "\N{U+2228}";
use constant _wedge     => "\N{U+2227}";
use constant _lsh       => "\N{U+21B0}";
use constant _rsh       => "\N{U+21B1}";


# Instruction mapping
my $tbl_instr_3graph = {
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
  '->�C'  => '\->\^oC',
  # G6
  'CLZ'   => 'CL\GS',
  '->CM'  => '\->CM',
  '->DEG' => '\->DEG',
  # G7
  '<-ENG' => '\<-ENG',
  'ENG->' => 'ENG\->',
  'e^x'   => 'e\^x',
  # G8
  '->�F'  => '\->\^oF',
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
  'xiy'   => 'x\imy',
#  'x+yi'  => 'x+y\im', only mode ALG
  'y^x'   => 'y\^x',
};

# Key sequences
my $tbl_instr_seq = {
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
  'CL\GS'   => '\+> CLEAR 4',
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
  '\<-ENG'  => '\<+ \<-ENG',
  'ENG\->'  => '\<+ ENG\->',
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
  'RANDOM'  => '\+> RAND',
  'RCL+'    => 'RCL +',
  'RCL-'    => 'RCL -',
  'RCL\.x'  => 'RCL \.x',
  'RCL\:-'  => 'RCL \:-',
  'REGX'    => 'EQN \R|v 1 ENTER',
  'REGY'    => 'EQN \R|v 2 ENTER',
  'REGZ'    => 'EQN \R|v 3 ENTER',
  'REGT'    => 'EQN \R|v 4 ENTER',
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
  'x\imy'   => '\<+ DISPLAY 9',
#  'x+y\im'  => '\<+ DISPLAY . 1',  only mode ALG
  '\y-'     => '\<+ \x-,\y- 2',
  '\y^'     => '\<+ L.R. 2',
};

# number sequences
my $tbl_num_seq = {
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

# EQN sequences
my $tbl_char_seq = {
  # NUL
  '\^b'   => '',
  '\^c'   => '\<+ CONST \.^ \.^ 2 \.< \BS \.>',
  '\^e'   => '\<+ CONST \.^ 4',
  '\^g'   => '\<+ CONST 2',
  '\^h'   => '\<+ CONST \.v \.v 2',
  '\^m'   => '\<+ CONST \.v 2 \BS',
  '\^n'   => '\<+ CONST \.v 4 \.< \BS \.>',
  '\^p'   => '\<+ CONST \.v 3 \.< \BS \.>',
  '\^r'   => '\<+ CONST \.v \.v \.v \.v 5 \BS',
  '\^t'   => '\<+ CONST \.^ \.^ 4 \BS \.< \BS \.>',
  '\^v'   => '',
  '\^w'   => '',
  '\^x'   => '',
  '\^y'   => '',
  '\015'  => '\<+ CONST 5 \.< \BS \.>',
  '\016'  => '\<+ CONST 1',
  '\017'  => '\<+ CONST \.v \.v \.v 2',
  '\018'  => '\<+ CONST 3',
  '\^k'   => '\<+ CONST \.v \.v 1',
  '\020'  => '\<+ CONST \.v \.v \.v 1',
  '\021'  => '\<+ CONST \.^ 3 \BS',
  '\^d'   => '',
  '\023'  => '\<+ CONST \.v \.v 3',
  '\024'  => '\<+ CONST \.^ \.^ 3',
  '\Ga'   => '\<+ CONST \.^ \.^ 1',
  '\Gl'   => '\<+ CONST \.^ \.^ \.^ 2 \BS',
  '\O/'   => '\<+ CONST \.v \.v 4 \BS',
  '\Gg'   => '\<+ CONST \.^ \.^ 5 \BS',
  '\oo'   => '\<+ CONST 6 \.< \BS \.>',
  '\Ge'   => '\<+ CONST \.v \.v 6 \BS',
  ' '     => '\+> SPACE',
  '!'     => '\+> !',
  '"'     => '',
  '\GH'   => '',
  '\036'  => '',
  '%'     => '\+> % \.> \.> \BS \BS \BS',
  '\^-'   => '+/-',
  "'"     => '',
  '('     => '() \.> \BS',
  ')'     => '() \BS \.>',
  '*'     => '\.x',                       # \.x
  # '+'   => '+',
  ','     => '\<+ % \.> \.> \BS \BS \BS', # \;,
  # '-'   => '-',
  '.'     => '',
  '/'     => '\:-',                       # \:-
  # '0'   => '0',
  # '1'   => '1',
  # '2'   => '2',
  # '3'   => '3',
  # '4'   => '4',
  # '5'   => '5',
  # '6'   => '6',
  # '7'   => '7',
  # '8'   => '8',
  # '9'   => '9',
  ':'     => '',
  '\[]'   => '',
  # '<'   => '<',
  '='     => '\<+ =',
  # '>'   => '>',
  '?'     => '',
  ';'     => '',
  'A'     => 'RCL A',
  'B'     => 'RCL B',
  'C'     => 'RCL C',
  'D'     => 'RCL D',
  'E'     => 'RCL E',
  'F'     => 'RCL F',
  'G'     => 'RCL G',
  'H'     => 'RCL H',
  'I'     => 'RCL I',
  'J'     => 'RCL J',
  'K'     => 'RCL K',
  'L'     => 'RCL L',
  'M'     => 'RCL M',
  'N'     => 'RCL N',
  'O'     => 'RCL O',
  'P'     => 'RCL P',
  'Q'     => 'RCL Q',
  'R'     => 'RCL R',
  'S'     => 'RCL S',
  'T'     => 'RCL T',
  'U'     => 'RCL U',
  'V'     => 'RCL V',
  'W'     => 'RCL W',
  'X'     => 'RCL X',
  'Y'     => 'RCL Y',
  'Z'     => 'RCL Z',
  '['     => '\<+ [] \.> \BS',
  '\092'  => '\+> BASE 8',                # b
  ']'     => '\<+ [] \BS \.>',
  '^'     => 'y^x',
  '_'     => '',
  '\096'  => '\+> BASE 7',                # o
  'a'     => '',
  'b'     => '\+> BASE 8',                # \092
  'c'     => '',
  'd'     => '\+> BASE 5',                # \252
  'e'     => 'E',                         # \231
  'f'     => '',
  'g'     => '',
  'h'     => '\+> BASE 6',                # \235
  'i'     => '\im',                       # \im
  'j'     => '',
  'k'     => '',
  'l'     => '',
  'm'     => '\<+ L.R. 4',                # \179
  'n'     => '\+> SUMS 1',                # \128
  'o'     => '\+> BASE 7',                # \096
  'p'     => '',
  'q'     => '',
  'r'     => '\<+ L.R. 3',                # \171
  's'     => '\+> S,\Gs 1 \BS',           # \125
  't'     => '',
  'u'     => '',
  'v'     => '',
  'w'     => '\+> \x-,\y- 3 \.< \BS \.>',               # \_w
  'x'     => '\+> S,\Gs 1 \.< \BS \.>',                 # \_x
  'y'     => '\+> S,\Gs 2 \.< \BS \.>',                 # \_y
  'z'     => '',
  '\_b'   => '\<+ L.R. 5',
  '\<-'   => '',
  '\125'  => '\+> S,\Gs 1 \BS',           # s
  '\126'  => '',
  '\!?'   => '',
  '\128'  => '\+> SUMS 1',                # n
  # '\:-' => '\:-',                       # /
  # '\.x' => '\.x',                       # *
  '\v/'   => '',
  '\.S'   => '',
  '\GS'   => '\+> SUM 2 \BS',
  '\134'  => '',
  '\pi'   => '\<+ \pi',
  '\136'  => '',
  '\<='   => '',
  '\>='   => '',
  '\=/'   => '',
  '\_y'   => '\+> S,\Gs 2 \.< \BS \.>',                 # y
  '\->'   => '\+> \->l \.> \BS \BS \BS',
  '\_x'   => '\+> S,\Gs 1 \.< \BS \.>',                 # x
  '\Gm'   => '\<+ CONST \.v \.v \.v 4 \BS',             # �
  '�'     => '\<+ CONST \.v \.v \.v 4 \BS',             # \Gm
  '\144'  => '',
  '\145'  => '\+> SUM 4 \.< \BS \BS \.>',               # �
  '�'     => '\+> SUM 4 \.< \BS \BS \.>',               # \145
  '\146'  => '',
  '\147'  => '',
  '\^o'   => '\<+ ->\^oF \.> \BS \BS \BS \.< \BS \.>',  # �
  '�'     => '\<+ ->\^oF \.> \BS \BS \BS \.< \BS \.>',  # \^o
  '"'     => '',
  '\150'  => '',
  '\151'  => '',
  '\152'  => '',
  '\153'  => '',
  '\154'  => '',
  '\155'  => '',
  '\156'  => '',
  '\157'  => '\<+ CONST \.^ \.^ 2',
  '\Gh'   => '\+> \Gh',
  '\159'  => '',
  '\160'  => '',
  '\161'  => '',
  '\162'  => '',
  '\163'  => '',
  '\164'  => '',
  '\165'  => '',
  '~'     => '',
  '\167'  => '\<+ CONST \.^ \.^ 4 \BS \BS',
  '\^='   => '',
  '\_x'   => '\+> S,\Gs 1 \.< \BS \.>',     # x
  '\GD'   => '',
  '171'   => '\<+ L.R. 3',                  # r
  '172'   => '',
  '\,('   => '',
  '\Gs'   => '\+> S,\Gs 3 \BS',
  '\x-'   => '\<+ \x-,\y- 1',
  '\y-'   => '\<+ \x-,\y- 2',
  '\x^'   => '\<+ L.R. 1 \.> \BS \BS',
  '\y^'   => '\<+ L.R. 2 \.> \BS \BS',
  '\179'  => '\<+ L.R. 4',                  # m
  '\180'  => '',
  '\181'  => '',
  '\182'  => '',
  '\^0'   => '',
  '\^1'   => '\<+ CONST \.^ 1 \.< \BS \.>',
  '\^2'   => '\<+ CONST \.^ 2 \.< \BS \.>',
  '\^3'   => '',
  '\^4'   => '',
  '\^5'   => '',
  '\^6'   => '',
  '\^7'   => '',
  '\^8'   => '',
  '\^9'   => '',
  '\_w'   => '\+> \x-,\y- 3 \.< \BS \.>',   # w
  '\194'  => '',
  '\195'  => '',
  '\^A'   => '',
  '\^B'   => '\<+ CONST \.v \.v \.v 5 \.< \BS \.>',
  '\^C'   => '\<+ CONST \.^ 1 \BS ',
  '\^D'   => '',
  '\^E'   => '',
  '\^F'   => '',
  '\^G'   => '\<+ CONST \.^ 3 \BS',
  '\^H'   => '',
  '\^I'   => '',
  '\^J'   => '',
  '\^K'   => '',
  '\^L'   => '',
  '\^M'   => '',
  '\^N'   => '\<+ CONST 5 \BS',
  '\^O'   => '',
  '\211'  => '',
  '\Gn'   => '',
  '\213'  => '',
  '\214'  => '',
  '\215'  => '',
  '\^a'   => '\<+ CONST \.v \.v 5 \BS',
  '\217'  => '',
  '\_p'   => '',
  '\219'  => '',
  '\|^'   => '',
  '\|v'   => '',
  '\222'  => '',
  '\),'   => '',
  '\^,'   => '',
  '\Y_'   => '',
  '\^.'   => '',
  '\^u'   => '\<+ CONST \.v \.v \.v 3',
  '\;('   => '',
  '\;)'   => '',
  '\230'  => '',
  '\231'  => 'E',                           # e
  '\232'  => '',
  '\233'  => '',
  '\^?'   => '',
  '\^h'   => '\+> BASE 6',                  # h
  # '\im' => '\im',
  '\^P'   => '',
  '\^Q'   => '',
  '\^R'   => '\<+ CONST 6 \BS',
  '\^S'   => '',
  '\^T'   => '',
  '\^U'   => '',
  '\^V'   => '\<+ CONST 4 \BS',
  '\^W'   => '',
  '\^X'   => '',
  '\^Y'   => '',
  '\^Z'   => '\<+ CONST \.^ \.^ \.^ 1 \BS',
  '\^+'   => '',
  '\^i'   => '',
  '\250'  => '',
  '\251'  => '',
  '\252'  => '\+> BASE 5',                  # d
  '\;,'   => '\+> % \BS \BS \BS \BS \BS \.> \.> \BS',   # ,
  '\;.'   => '',
  '\|>'   => 'STO \CC',
  # additional char
  '�'     => '',
  '#'     => '',
  '{'     => '',
  '|'     => '',
  '}'     => '',
};

# Optimize sequences
my $tbl_opt_seq = {
  # CONST
  '\<+ CONST 4 \BS \<+ CONST \.v 2 \BS'             => '\<+ CONST 4',                   # \^V\^m
  '\<+ CONST 5 \BS \<+ CONST 5 \.< \BS \.>'         => '\<+ CONST 5',                   # \^N\015
  '\<+ CONST 6 \BS \<+ CONST 6 \.< \BS \.>'         => '\<+ CONST 6',                   # \^R\oo
  '\<+ CONST \.^ 4 \<+ CONST 4 \BS'                 => '\<+ CONST \.v 1',               # \^e\^V
  '\<+ CONST \.v 2 \BS \<+ CONST \.^ 4'             => '\<+ CONST \.v 2',               # \^m\^e
  '\<+ CONST \.v 2 \BS \<+ CONST \.v 3 \.< \BS \.>' => '\<+ CONST \.v 3',               # \^m\^p
  '\<+ CONST \.v 2 \BS \<+ CONST \.v 4 \.< \BS \.>' => '\<+ CONST \.v 4',               # \^m\^n
  '\<+ CONST \.v 2 \BS \<+ CONST \.v \.v \.v 4 \BS' => '\<+ CONST \.v 5',               # \^m\Gm
  '\<+ CONST \.v \.v 4 \BS \<+ CONST \.^ 3 \BS'     => '\<+ CONST \.v \.v 4',           # \O/\021
  '\<+ CONST \.v \.v 5 \BS \<+ CONST \.^ 3 \BS'     => '\<+ CONST \.v \.v 5',           # \^a\021
  '\<+ CONST \.v \.v 6 \BS \<+ CONST \.^ 3 \BS'     => '\<+ CONST \.v \.v 6',           # \Ge\021
  '\<+ CONST \.v \.v \.v 4 \BS \<+ CONST \.^ 3 \BS' => '\<+ CONST \.v \.v \.v 4',       # \Gm\021
  '\<+ CONST \.v \.v \.v 4 \BS \<+ CONST \.v \.v \.v 5 \.< \BS \.>'
                                                    => '\<+ CONST \.v \.v \.v 5',       # \Gm\^B
  '\<+ CONST \.v \.v \.v 4 \BS \<+ CONST 5 \BS'     => '\<+ CONST \.v \.v \.v 6',       # \Gm\^N
  '\<+ CONST \.v \.v \.v 4 \BS \<+ CONST \.v 3 \.< \BS \.>'
                                                    => '\<+ CONST \.v \.v \.v \.v 1',   # \Gm\^p
  '\<+ CONST \.v \.v \.v 4 \BS \<+ CONST \.^ 4'     => '\<+ CONST \.v \.v \.v \.v 2',   # \Gm\^e
  '\<+ CONST \.v \.v \.v 4 \BS \<+ CONST \.v 4 \.< \BS \.>'
                                                    => '\<+ CONST \.v \.v \.v \.v 3',   # \Gm\^n
  '\<+ CONST \.v \.v \.v 4 \BS \<+ CONST \.v \.v \.v 4 \BS'
                                                    => '\<+ CONST \.v \.v \.v \.v 4',   # \Gm\Gm
  '\<+ CONST \.v \.v \.v \.v 5 \BS \<+ CONST \.v 4 \.< \BS \.>'
                                                    => '\<+ CONST \.v \.v \.v \.v 5',   # \^r\^n
  '\<+ CONST \.^ \.^ \.^ 1 \BS \<+ CONST \.^ 3 \BS' => '\<+ CONST \.^ \.^ \.^ 1',       # \^Z\021
  '\<+ CONST \.^ \.^ \.^ 2 \BS \<+ CONST \.^ \.^ 2 \.< \BS \.>'
                                                    => '\<+ CONST \.^ \.^ \.^ 2',       # \Gl\^c
  '\<+ CONST \.^ \.^ \.^ 2 \<+ CONST \.v 4 \.< \BS \.>'
                                                    => '\<+ CONST \.^ \.^ \.^ 3',       # \Gl\^c\^n
  '\<+ CONST \.^ \.^ \.^ 2 \<+ CONST \.v 3 \.< \BS \.>'
                                                    => '\<+ CONST \.^ \.^ \.^ 4',       # \Gl\^c\^p
  '\<+ CONST \.^ \.^ 4 \BS \BS \<+ CONST \.^ \.^ 4 \BS \.< \BS \.> \<+ CONST \.v 2 \BS'
                                                    => '\<+ CONST \.^ \.^ 4',           # \167\^t\^m
  '\<+ CONST \.^ \.^ 5 \BS \<+ CONST \.v 3 \.< \BS \.>'
                                                    => '\<+ CONST \.^ \.^ 5',           # \Gg\^p
  '\<+ CONST \.^ 1 \BS  \<+ CONST \.^ 1 \.< \BS \.>'
                                                    => '\<+ CONST \.^ 1',               # \^C\^1
  '\<+ CONST \.^ 1 \BS  \<+ CONST \.^ 2 \.< \BS \.>'
                                                    => '\<+ CONST \.^ 2',               # \^C\^2
  '\<+ CONST \.^ 3 \BS \<+ CONST \.^ 3 \BS'         => '\<+ CONST \.^ 3',               # \^G\021
  # R\|v
  'RCL R RCL E RCL G RCL X'                         => 'R\|v 1',                        # REGX
  'RCL R RCL E RCL G RCL Y'                         => 'R\|v 2',                        # REGY
  'RCL R RCL E RCL G RCL Z'                         => 'R\|v 3',                        # REGZ
  'RCL R RCL E RCL G RCL T'                         => 'R\|v 4',                        # REGT
  # SIN
  'RCL S RCL I RCL N'                               => 'SIN \.> \BS \BS',               # SIN
  'RCL A RCL S RCL I RCL N'                         => '\+> SIN \.> \BS \BS',           # ASIN
  # COS
  'RCL C RCL O RCL S'                               => 'COS \.> \BS \BS',               # COS
  'RCL A RCL C RCL O RCL S'                         => '\+> COS \.> \BS \BS',           # ACOS
  # TAN
  'RCL T RCL A RCL N'                               => 'TAN \.> \BS \BS',               # TAN
  'RCL I RCL N RCL T RCL G'                         => '\<+ INTG 4 \.> \BS \BS',        # INTG
  'RCL A RCL T RCL A RCL N'                         => '\+> TAN \.> \BS \BS',           # ATAN
  # 1/x
  'RCL I RCL N RCL V'                               => '1/x \.> \BS \BS',               # INV
  'RCL A RCL L RCL O RCL G'                         => '\<+ 1/x \.> \BS \BS',           # ALOG
  # ENTER
  'RCL L RCL A RCL S RCL T \+> S,\Gs 1 \.< \BS \.>' => '\+> ENTER',                     # LASTx
  # \v/x
  'RCL S RCL Q RCL R RCL T'                         => '\v/x \.> \BS \BS',              # SQRT
  'RCL X RCL R RCL O RCL O RCL T'                   => '\<+ x\v/y \.> \.> \BS \BS',     # XROOT
  # ()
  '() \.> \BS () \BS \.>'                           => '() \.>',                        # ()
  '\<+ [] \.> \BS \<+ [] \BS \.>'                   => '\<+ [] \.>',                    # []
  # 7
  '\+> \->l \.> \BS \BS \BS \<+ ->\^oF \.> \BS \BS \BS \.< \BS \.> RCL F'
                                                    => '\<+ \->\^oF \.> \BS \BS',       # \->\^oF
  '\+> \->l \.> \BS \BS \BS \<+ ->\^oF \.> \BS \BS \BS \.< \BS \.> RCL C'
                                                    => '\+> \->\^oC \.> \BS \BS',       # \->\^oC
  # 8
  'RCL H RCL M RCL S \+> \->l \.> \BS \BS \BS'      => '\<+ HMS\-> \.> \BS \BS',        # HMS\->
  '\+> \->l \.> \BS \BS \BS RCL H RCL M RCL S'      => '\+> \->HMS \.> \BS \BS',        # \->HMS
  # 9
  '\+> \->l \.> \BS \BS \BS RCL R RCL A RCL D'      => '\<+ \->RAD \.> \BS \BS',        # \->RAD
  '\+> \->l \.> \BS \BS \BS RCL D RCL E RCL G'      => '\+> \->DEG \.> \BS \BS',        # \->DEG
  # \:-
  '\+> % \.> \.> \BS \BS \BS RCL C RCL H RCL G'     => '\<+ %CHG \.> \.> \BS \BS \BS',  # %CHG
  # 4
  '\+> \->l \.> \BS \BS RCL B'                      => '\<+ \->lb \.> \BS \BS',         # \->LB
  '\+> \->l \.> \BS \BS \BS RCL K RCL G'            => '\+> \->kg \.> \BS \BS',         # \->KG
  # 5
  '\+> \->l \.> \BS \BS \BS RCL M RCL I RCL L RCL E'
                                                    => '\<+ \->MILE \.> \BS \BS',       # \->MILE
  '\+> \->l \.> \BS \BS \BS RCL K RCL M'            => '\+> \->KM \.> \BS \BS',         # \->KM
  # 6
  '\+> \->l \.> \BS \BS \BS RCL G RCL A RCL L'      => '\<+ \->gal \.> \BS \BS',        # \->GAL
  '\+> \->l \.> \BS \BS \BS RCL L'                  => '\+> \->l \.> \BS \BS',          # \->L
  # \.x
  '\+> SUMS 1 RCL C \<+ L.R. 3'                     => '\<+ nCr \.> \.> \BS \BS \BS',   # nCr
  '\+> SUMS 1 RCL P \<+ L.R. 3'                     => '\+> nCr \.> \.> \BS \BS \BS',   # nPr
  # 2
  '\+> \->l \.> \BS \BS \BS RCL G RCL A RCL L'      => '\<+ \->gal \.> \BS \BS',        # \->GAL
  '\+> \->l \.> \BS \BS \BS RCL L'                  => '\+> \->l \.> \BS \BS',          # \->L
  # 3
  'RCL S RCL E RCL E RCL D'                         => '\<+ SEED \.> \BS \BS',          # SEED
  'RCL R RCL A RCL N RCL D'                         => '\+> RAND',                      # RAND
  # -
  '\+> SUM 2 \BS \+> S,\Gs 1 \.< \BS \.>'           => '\+> SUM 2',                     # \GSx
  '\+> SUM 2 \BS \+> S,\Gs 2 \.< \BS \.>'           => '\+> SUM 3',                     # \GSy
  '\+> SUM 2 \+> SUM 4 \.< \BS \BS \.>'             => '\+> SUM 4',                     # \GSx\145
  '\+> S,\Gs 1 \.< \BS \.> \+> SUM 4 \.< \BS \BS \.>'
                                                    => '\+> SUM 4 \.< \.< \BS \.> \.>', # x\145
  # 0
  '() \.> \BS RCL I () \BS \.>'                     => 'RCL 0',                         # (I)
  # .
  '() \.> \BS RCL J () \BS \.>'                     => 'RCL .',                         # (J)
  # +
  '\<+ \x-,\y- 1 \+> \x-,\y- 3 \.< \BS \.>'         => '\<+ \x-,\y- 3',                 # \x-\_w
  '\+> S,\Gs 1 \BS \+> S,\Gs 1 \.< \BS \.>'         => '\+> S,\Gs 1',                   # sx
  '\+> S,\Gs 1 \BS \+> S,\Gs 2 \.< \BS \.>'         => '\+> S,\Gs 2',                   # sy
  '\+> S,\Gs 3 \BS \+> S,\Gs 1 \.< \BS \.>'         => '\+> S,\Gs 3',                   # \Gsx
  '\+> S,\Gs 3 \BS \+> S,\Gs 2 \.< \BS \.>'         => '\+> S,\Gs 4',                   # \Gsy
};

# plaintext mapping
my $tbl_char_plain = {
  # equ charset
  '\^c'   => '^c',
  '\^e'   => '^e',
  '\^g'   => '^g',
  '\^h'   => '^h',
  '\^m'   => '^m',
  '\^n'   => '^n',
  '\^p'   => '^p',
  '\^r'   => '^r',
  '\^t'   => '^t',
  '\015'  => '^A',
  '\016'  => 'c',
  '\017'  => 'F',
  '\018'  => 'G',
  '\^k'   => '^k',
  '\020'  => 'R',
  '\021'  => '^o',
  '\023'  => 'h',
  '\024'  => 't',
  '\Ga'   => 'a',
  '\Gl'   => 'l',
  '\O/'   => 'Ph',
  '\Gg'   => 'g',
  '\oo'   => 'oo',
  '\Ge'   => 'e',
  '\^-'   => '^-',
  '\092'  => 'b',
  '\096'  => 'o',
  '\_b'   => 'b',
  '\125'  => 's',
  '\128'  => 'n',
  '\:-'   => '/',
  # '/'   => '/',
  '\.x'   => '*',
  # '*'   => '*',
  '\GS'   => 'Z',
  '\pi'   => 'pi',
  '\_y'   => 'y',
  '\->'   => '->',
  '\_x'   => 'x',
  '\Gm'   => 'm',
  '\145'  => '^2',
  '\^o'   => '^o',
  '\157'  => '^z',
  '\Gh'   => 't',
  '\167'  => '^a',
  '\171'  => 'r',
  '\Gs'   => 'z',
  '\x-'   => 'x',
  '\y-'   => 'y',
  '\x^'   => 'x',
  '\y^'   => 'y',
  '\179'  => 'm',
  '\^1'   => '^1',
  '\^2'   => '^2',
  '\_w'   => 'w',
  '\^B'   => '^B',
  '\^C'   => '^C',
  '\^G'   => '^G',
  '\^N'   => '^N',
  '\^a'   => '^a',
  '\^u'   => '^u',
  '\231'  => 'e',
  # 'e'   => 'e',
  '\235'  => 'h',
  '\im'   => 'i',
  # 'i'   => 'i',
  '\^R'   => '^R',
  '\^V'   => '^V',
  '\^Z'   => '^Z',
  '\252'  => 'd',
  '\;,'   => ',',
  '\|>'   => '>',
  # non equ charset
  '\v/x'  => 'sqrt',
  'x\v/y' => 'xroot',
  '\.S'   => '$',
  '\<='   => '<=',
  '\>='   => '>=',
  '\=/'   => '!=',
  '\<-'   => '<-',
  '\|v'   => 'v',
  '\|^'   => '^',
  '\^x'   => '^x',
  # extra
  '\BS'   => 'bksp',
  '\CC'   => 'cancel',
  '\.<'   => 'left',
  '\.>'   => 'right',
  '\.v'   => 'down',
  '\.^'   => 'up',
  '\<+'   => 'ctrl',
  '\+>'   => 'shift',
};

# Markdown mapping
my $tbl_char_markdown = {
  # equ charset
  '\^c'   => '<sup>c</sup>',
  '\^e'   => '<sup>e</sup>',
  '\^g'   => '<sup>g</sup>',
  '\^h'   => '<sup>h</sup>',
  '\^m'   => '<sup>m</sup>',
  '\^n'   => '<sup>n</sup>',
  '\^p'   => '<sup>p</sup>',
  '\^r'   => '<sup>r</sup>',
  '\^t'   => '<sup>t</sup>',
  '\015'  => '<sup><sub>A</sub></sup>',
  '\016'  => '<sup>&copf;</sup>',
  '\017'  => '<sup>&Fopf;</sup>',
  '\018'  => '<sup>&Gopf;</sup>',
  '\^k'   => '<sup>k</sup>',
  '\020'  => '<sup>&Ropf;</sup>',
  '\021'  => '<sup>o</sup>',
  '\023'  => '<sup>&hbar;</sup>',
  '\024'  => '<sup>&topf;<sup>',
  '\Ga'   => '&alpha;',
  '\Gl'   => '&lambda;',
  '\O/'   => '&Phi;',
  '\Gg'   => '&gamma;',
  '\oo'   => '&infin;',
  '\Ge'   => '&epsilon;',
  '\^-'   => '<sup>-</sup>',
  '\092'  => 'b',
  '\096'  => 'o',
  '\_b'   => '<sub>b</sub>',
  '\125'  => 's',
  '\128'  => 'n',
  '\:-'   => '&divide;',
  # '/'   => '/',
  '\.x'   => '&times;',
  # '*'   => '*',
  '\GS'   => '&Sigma;',
  '\pi'   => '&pi;',
  '\_y'   => '<sub>y</sub>',
  '\->'   => '&rarr;',
  '\_x'   => '<sub>x</sub>',
  '\Gm'   => '&mu;',
  '\145'  => '&sup2;',
  '\^o'   => '&deg;',
  '\157'  => '<sup>&sigma;</sup>',
  '\Gh'   => '&theta;',
  '\167'  => '<sup>&alpha;</sup>',
  '\171'  => 'r',
  '\Gs'   => '&sigma;',
  '\x-'   => 'x&#x0304;',
  '\y-'   => 'y&#x0304;',
  '\x^'   => 'x&#x0302;',
  '\y^'   => 'y&#x0302;',
  '\179'  => 'm',
  '\^1'   => '<sup>1</sup>',
  '\^2'   => '<sup>2</sup>',
  '\_w'   => '<sub>w</sub>',
  '\^B'   => '<sup>B</sup>',
  '\^C'   => '<sup>C</sup>',
  '\^G'   => '<sup>G</sup>',
  '\^N'   => '<sup>N</sup>',
  '\^a'   => '<sup>a</sup>',
  '\^u'   => '<sup>u</sup>',
  '\231'  => '<sup><sub>E</sub></sup>',
  # 'e'   => _capE,
  '\235'  => 'h',
  '\im'   => '&iscr;',
  # 'i'   => _iscr,
  '\^R'   => '<sup>R</sup>',
  '\^V'   => '<sup>V</sup>',
  '\^Z'   => '<sup>Z</sup>',
  '\252'  => 'd',
  '\;,'   => ',',
  '\|>'   => '&#x25BA;',
  # non equ charset
  '\v/'   => '&radic;',
  '\.S'   => '&int;',
  '\<='   => '&le;',
  '\>='   => '&ge;',
  '\=/'   => '&ne;',
  '\<-'   => '&larr;',
  '\|v'   => '&darr;',
  '\|^'   => '&uarr;',
  '\^x'   => '<sup>x</sup>',
  # extra
  '\BS'   => '&#x21E6;',
  '\CC'   => '&#x1F132;',
  '\.<'   => '<',
  '\.>'   => '>',
  '\.v'   => '&or;',
  '\.^'   => '&and;',
  '\<+'   => '&lsh;',
  '\+>'   => '&rsh;',
};


# Unicode mapping
my $tbl_char_unicode = {
  # equ charset
  '\^c'   => _supc,
  '\^e'   => _supe,
  '\^g'   => _supg,
  '\^h'   => _suph,
  '\^m'   => _supm,
  '\^n'   => _supn,
  '\^p'   => _supp,
  '\^r'   => _supr,
  '\^t'   => _supt,
  '\015'  => _capA,
  '\016'  => _copf,
  '\017'  => _Fopf,
  '\018'  => _Gopf,
  '\^k'   => _supk,
  '\020'  => _Ropf,
  '\021'  => _supo,
  '\023'  => _suph._macr,
  '\024'  => _topf,
  '\Ga'   => _alpha,
  '\Gl'   => _lambda,
  '\O/'   => _Phi,
  '\Gg'   => _gamma,
  '\oo'   => _infin,
  '\Ge'   => _epsilon,
  '\^-'   => _supminus,
  '\092'  => 'b',
  '\096'  => 'o',
  '\_b'   => 'b',
  '\125'  => 's',
  '\128'  => 'n',
  '\:-'   => _divide,
  # '/'   => '/',
  '\.x'   => _times,
  # '*'   => '*',
  '\GS'   => _Sigma,
  '\pi'   => _pi,
  '\_y'   => 'y',
  '\->'   => _rarr,
  '\_x'   => 'x',
  '\Gm'   => '�',
  '\145'  => _sup2,
  '\^o'   => '�',
  '\157'  => _sigma,
  '\Gh'   => _theta,
  '\167'  => _supalpha,
  '\171'  => 'r',
  '\Gs'   => _sigma,
  '\x-'   => 'x'._macr,
  '\y-'   => _ymacr,
  '\x^'   => 'x'._circ,
  '\y^'   => _ycirc,
  '\179'  => 'm',
  '\^1'   => _sup1,
  '\^2'   => _sup2,
  '\_w'   => 'w',
  '\^B'   => _supB,
  '\^C'   => _capC,
  '\^G'   => _supG,
  '\^N'   => _supN,
  '\^a'   => _supa,
  '\^u'   => _supu,
  '\231'  => _capE,
  # 'e'   => _capE,
  '\235'  => 'h',
  '\im'   => _iscr,
  # 'i'   => _iscr,
  '\^R'   => _supR,
  '\^V'   => _supV,
  '\^Z'   => _capZ,
  '\252'  => 'd',
  '\;,'   => ',',
  '\|>'   => _brtri,
  # non equ charset
  '\v/'   => _sqrt,
  '\.S'   => _int,
  '\<='   => _leq,
  '\>='   => _geq,
  '\=/'   => _neq,
  '\<-'   => _larr,
  '\|v'   => _darr,
  '\|^'   => _uarr,
  '\^x'   => _supx,
  # extra
  '\BS'   => _bksp,
  '\CC'   => _cancel,
  '\.<'   => '<',
  '\.>'   => '>',
  '\.v'   => _vee,
  '\.^'   => _wedge,
  '\<+'   => _lsh,
  '\+>'   => _rsh,
};

my $lbl = '0';
my $loc = $0;
my $out = '';
my $response;
my $jump_targets = {};

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
    elsif ($entry->{type} eq 'vector') {
      $out .= sprintf_vector_statement( $statement );
    }
    elsif ($entry->{type} eq 'complex') {
      $out .= sprintf_complex_statement( $statement );
    }
    elsif ($entry->{type} eq 'instruction') {
      my $mnemonic = $statement;
      # instructions without an operand
      if ( grep { $_ eq $mnemonic } @instructions, @functions, @register ) {
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

# option --jumpmark
if ($jumpmark) {
  foreach my $lbl (keys %$jump_targets) {
    $out =~ s/^$lbl/$lbl\*/gm;
  }
}

# option --unicode
if ($unicode) {
  foreach (keys %$tbl_char_unicode) {
    my $a = quotemeta $_;
    my $b = $tbl_char_unicode->{$_};
    $out =~ s/$a/$b/g;
  }
  binmode(STDOUT, ":utf8");
}
# option --markdown
elsif ($markdown) {
  foreach (keys %$tbl_char_markdown) {
    my $a = quotemeta $_;
    my $b = $tbl_char_markdown->{$_};
    $out =~ s/$a/$b/g;
  }
}
# option --plain
elsif ($plain) {
  foreach (keys %$tbl_char_plain) {
    my $a = quotemeta $_;
    my $b = $tbl_char_plain->{$_};
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
      $keysequence .= sprintf("\t\t; %s", $tbl_num_seq->{'dec'});
    }
    elsif ($base eq 'h') {
      $keysequence .= sprintf("\t\t; %s", $tbl_num_seq->{'hex'});
    }
    elsif ($base eq 'o') {
      $keysequence .= sprintf("\t\t; %s", $tbl_num_seq->{'oct'});
    }
    elsif ($base eq 'b') {
      $keysequence .= sprintf("\t\t; %s", $tbl_num_seq->{'bin'});
    }
    else {
      $keysequence = "\t\t;";
    }

    # sequence for mantissa and exponent
    foreach (split //, $digits) {
      exists $tbl_num_seq->{$_} and
        $keysequence .= sprintf(" %s", $tbl_num_seq->{$_} );
    }
    if ($sign) {
      $keysequence .= sprintf(" %s", $tbl_num_seq->{'-'} );
    }
    if ($exponent) {
      $keysequence .= sprintf(" %s", $tbl_num_seq->{'e'} );
      foreach (split //, $exponent) {
        exists $tbl_num_seq->{$_} and
          $keysequence .= sprintf(" %s", $tbl_num_seq->{$_} );
      }
    }

    # end sequence
    if ($base) {
      $keysequence .= sprintf(" %s", $tbl_num_seq->{$base});
      $keysequence .= sprintf(" %s", $tbl_num_seq->{'dec'});
    }
    $keysequence .= ' ENTER';
  }
  return sprintf("%s%03d\t%s%s\n", $lbl, ++$loc, $number, $keysequence);
}

# vector statement
sub sprintf_vector_statement {
  my $vector = shift;
  my $keysequence = '';

  $vector =~ /\[(\S+)\]/;
  my ($a, $b, $c) = split /,/, $1;
  defined $a and defined $b or
    print STDERR "Warn: unknown syntax for vector number '$vector'\n" and next;

  if ($shortcut) {
    if (defined $c) {
      $keysequence = sprintf("\t\t; %s \<+ , %s \<+ , %s ENTER", $a, $b, $c);
    } else {
      $keysequence = sprintf("\t\t; %s \<+ , %s ENTER", $a, $b);
    }
  }
  return sprintf("%s%03d\t%s%s\n", $lbl, ++$loc, $vector, $keysequence);
}

# complex statement
sub sprintf_complex_statement {
  my $complex = shift;
  my $keysequence = '';

  my ($a, $sep, $b) = split /([it])/, $complex;
  defined $a and defined $b or
    print STDERR "Warn: unknown syntax for complex number '$complex'\n" and next;

  $sep =~ s/e/\\231/;
  $sep =~ s/i/\\im/;
  $sep =~ s/t/\\Gh/;
  my $seq = exists $tbl_instr_seq->{sep} ? $tbl_instr_seq->{sep} : $sep;

  defined $shortcut and
    $keysequence = sprintf("\t\t; %s %s %s ENTER", $a, $seq, $b);
  return sprintf("%s%03d\t%s%s%s%s\n", $lbl, ++$loc, $a, $sep, $b, $keysequence);
}

# instructions without an operand
sub sprintf_single_instruction {
  my $mnemonic = shift;
  my $keysequence = '';

  exists $tbl_instr_3graph->{$mnemonic} and
    $mnemonic = $tbl_instr_3graph->{$mnemonic};

  defined $shortcut and
    $keysequence = sprintf("\t\t; %s", exists $tbl_instr_seq->{$mnemonic} ? $tbl_instr_seq->{$mnemonic} : $mnemonic);

  # special handling for ENG
  $mnemonic = 'ENG' if $mnemonic eq 'ENG\->';
  return sprintf("%s%03d\t%s%s\n", $lbl, ++$loc, $mnemonic, $keysequence);
}

# instructions with absolute address
sub sprintf_address_instruction {
  my $mnemonic = shift;
  my $addr = shift;
  my $keysequence = '';

  exists $tbl_instr_3graph->{$mnemonic} and
    $mnemonic = $tbl_instr_3graph->{$mnemonic};

  $jump_targets->{$addr} = $addr;
  defined $shortcut and
    $keysequence = sprintf("\t; %s %s", exists $tbl_instr_seq->{$mnemonic} ? $tbl_instr_seq->{$mnemonic} : $mnemonic, $addr);
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

  exists $tbl_instr_3graph->{$mnemonic} and
    $mnemonic = $tbl_instr_3graph->{$mnemonic};

  if ( $response->{labels}->{$label}->{segment} eq $seq ) {
    my $near = $response->{labels}->{$label}->{statement} + $line - $loc + 1;
    my $digits = join(' ', split(//, sprintf("%03d", $near)));
    my $addr = sprintf("%s%03d", $lbl, $near);
    $jump_targets->{$addr} = $addr;
    defined $shortcut and
      $keysequence = sprintf("\t; %s %s %s", exists $tbl_instr_seq->{$mnemonic} ? $tbl_instr_seq->{$mnemonic} : $mnemonic, $lbl, $digits);
    return sprintf("%s%03d\t%s %s%03d%s\n", $lbl, ++$loc, $mnemonic, $lbl, $near, $keysequence);
  }
  else {
    print STDERR "Warn: far 'label' not supported yet\n";
    my $far = $response->{labels}->{$label}->{segment};
    my $near = $response->{labels}->{$label}->{statement} + 1;
    defined $shortcut and
      $keysequence = sprintf("\t; %s ...", exists $tbl_instr_seq->{$mnemonic} ? $tbl_instr_seq->{$mnemonic} : $mnemonic);
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

  exists $tbl_instr_3graph->{$mnemonic} and
    $mnemonic = $tbl_instr_3graph->{$mnemonic};

  if ($mnemonic =~ /LBL/) {
    # set line number if instruction is 'LBL'
    $lbl = $variable;
    $loc = 0;
  }
  my $space = $variable =~ /\([IJ]\)/ ? '' : ' ';   # indirects have no space
  defined $shortcut and
    $keysequence = sprintf("\t\t; %s %s", exists $tbl_instr_seq->{$mnemonic} ? $tbl_instr_seq->{$mnemonic} : $mnemonic, $variable);
  return sprintf("%s%03d\t%s%s%s%s\n", $lbl, ++$loc, $mnemonic, $space, $variable, $keysequence);
}

sub sprintf_number_instruction {
  my $mnemonic = shift;
  my $number = shift;
  my $keysequence = '';

  defined $number or
    print STDERR "Warn: missing type 'number' in instruction '$mnemonic'\n" and next;

  exists $tbl_instr_3graph->{$mnemonic} and
    $mnemonic = $tbl_instr_3graph->{$mnemonic};

  my $digits = $number < 10 ? $number : sprintf(". %d", $number % 10);
  defined $shortcut and
    $keysequence = sprintf("\t\t; %s %s", exists $tbl_instr_seq->{$mnemonic} ? $tbl_instr_seq->{$mnemonic} : $mnemonic, $digits);
  return sprintf("%s%03d\t%s %s%s\n", $lbl, ++$loc, $mnemonic, $number, $keysequence);
}

sub sprintf_equation_instruction {
  my $mnemonic = shift;
  my $definition = shift;
  my $keysequence = '';
  my $ret = '';

  defined $equations->{$definition} or
    print STDERR "Warn: missing 'equation' for instruction '$mnemonic'\n" and next;

  exists $tbl_instr_3graph->{$mnemonic} and
    $mnemonic = $tbl_instr_3graph->{$mnemonic};

  my $equation = $equations->{$definition};
  $equation =~ s/\//\\:-/;  # '/' => '\:-'
  $equation =~ s/\*/\\\.x/; # '*' => '\.x'
  $equation =~ s/\*/\\\.x/; # 'e' => '\231',
  $equation =~ s/\*/\\\.x/; # 'i' to '\im'

  if ($shortcut) {
 
    my $state = 0;
    my $char = '';
    foreach (split //, $equation)
    {
      $char .= $_;
      if ($state == 0) {
        if (/\\/) {
          $state = 1;
          $char = '\\';
        }
        else {
          my $seq = exists $tbl_char_seq->{$char} ? $tbl_char_seq->{$char} : $char;
          $keysequence .= sprintf(" %s", $seq) if length $seq > 0;
          $char = '';
        }
      }
      elsif ($state == 1) {
        if (/\\/) {
          $state = 0;
          my $seq = exists $tbl_char_seq->{$char} ? $tbl_char_seq->{$char} : $char;
          $keysequence .= sprintf(" %s", $seq) if length $seq > 0;
          $char = '';
        }
        elsif (/\d/) {
          $state = 2;
        }
        else {
          $state = 3;
        }
      }
      elsif ($state == 2) {
        if (/\d/) {
          $state = 3;
        }
        else {
          $state = 4;
        }
      }
      elsif ($state == 3) {
        if (/\\/) {
          $state = 4;
        }
        else {
          $state = 0;
          my $seq = exists $tbl_char_seq->{$char} ? $tbl_char_seq->{$char} : $char;
          $keysequence .= sprintf(" %s", $seq) if length $seq > 0;
          $char = '';
        }
      }
    }
  
    # optimize key sequences
    foreach (keys %$tbl_opt_seq) {
      my $a = quotemeta $_;
      my $b = $tbl_opt_seq->{$_};
      $keysequence =~ s/$a/$b/g;
    }

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
  -j, --jumpmark      Prints an asterisk (*) at the jump target
  -p, --plain         Output as Plain text (7-bit ASCII)
  -m, --markdown      Output as Markdown (inline HTML 5)
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
