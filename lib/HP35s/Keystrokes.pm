package HP35s::Keystrokes;
# ABSTRACT: Encode keystrokes for the HP35S calculator

use strict;
use warnings;

use version;
our $VERSION = version->declare('v0.5.0');

use Exporter 'import';
our @EXPORT_OK = qw(
  constant_keystrokes
  instruction_keystrokes
  number_keystroke
  char_keystrokes
  optimize_keystrokes
);

# Constant keystrokes
my $tbl_const_seq = {
  # '\im'      => '\im',
  '\pi'        => '\<+ \pi',

  '\016'        => '\<+ CONST 1',
  '\^g'         => '\<+ CONST 2',
  '\018'        => '\<+ CONST 3',
  '\^V\^m'      => '\<+ CONST 4',
  '\^N\015'     => '\<+ CONST 5',
  '\^R\oo'      => '\<+ CONST 6',
  '\^e\^V'      => '\<+ CONST \.v 1',
  '\^m\^e'      => '\<+ CONST \.v 2',
  '\^m\^p'      => '\<+ CONST \.v 3',
  '\^m\^n'      => '\<+ CONST \.v 4',
  '\^m\Gm'      => '\<+ CONST \.v 5',
  '\^k'         => '\<+ CONST \.v \.v 1',
  '\^h'         => '\<+ CONST \.v \.v 2',
  '\023'        => '\<+ CONST \.v \.v 3',
  '\O/\021'     => '\<+ CONST \.v \.v 4',
  '\^a\021'     => '\<+ CONST \.v \.v 5',
  '\Ge\021'     => '\<+ CONST \.v \.v 6',
  '\020'        => '\<+ CONST \.v \.v \.v 1',
  '\017'        => '\<+ CONST \.v \.v \.v 2',
  '\^u'         => '\<+ CONST \.v \.v \.v 3',
  '\Gm\021'     => '\<+ CONST \.v \.v \.v 4',
  '\Gm\^B'      => '\<+ CONST \.v \.v \.v 5',
  '\Gm\^N'      => '\<+ CONST \.v \.v \.v 6',
  '\Gm\^p'      => '\<+ CONST \.v \.v \.v \.v 1',
  '\Gm\^e'      => '\<+ CONST \.v \.v \.v \.v 2',
  '\Gm\^n'      => '\<+ CONST \.v \.v \.v \.v 3',
  '\Gm\Gm'      => '\<+ CONST \.v \.v \.v \.v 4',
  '\^r\^e'      => '\<+ CONST \.v \.v \.v \.v 5',
  '\^Z\021'     => '\<+ CONST \.^ \.^ \.^ 1',
  '\Gl\^c'      => '\<+ CONST \.^ \.^ \.^ 2',
  '\Gl\^c\^n'   => '\<+ CONST \.^ \.^ \.^ 3',
  '\Gl\^c\^p'   => '\<+ CONST \.^ \.^ \.^ 4',
  '\Ga'         => '\<+ CONST \.^ \.^ 1',
  '\157'        => '\<+ CONST \.^ \.^ 2',
  '\024'        => '\<+ CONST \.^ \.^ 3',
  '\167\^t\^m'  => '\<+ CONST \.^ \.^ 4',
  '\Gg\^p'      => '\<+ CONST \.^ \.^ 5',
  '\^C\^1'      => '\<+ CONST \.^ 1',
  '\^C\^2'      => '\<+ CONST \.^ 2',
  '\^G\021'     => '\<+ CONST \.^ 3',
  '\^e'         => '\<+ CONST \.^ 4',
};

# Instruction keystrokes
my $tbl_instr_seq = {
  # G2
  '10\^x'   => '\<+ 10\^x',
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
  '\Gh'     => '\+> \Gh',
  'ABS'     => '\+> ABS',
  'ACOS'    => '\+> ACOS',
  'ACOSH'   => '\<+ HYP \+> ACOS',
  'ALG'     => 'MODE 4',
  'ALOG'    => '\<+ 10\^x',
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
  '\->IN'   => '\<+ \->in',
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
  '\->LB'   => '\<+ \->lb',
  'LBL'     => '\+> LBL',
  'LN'      => '\+> LN',
  'LOG'     => '\<+ LOG',
  'm'       => '\<+ L.R. 4',
  # G11
  '\->MILE' => '\<+ \->MILE',
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
  'REGX'    => 'EQN R\|v 1 ENTER',
  'REGY'    => 'EQN R\|v 2 ENTER',
  'REGZ'    => 'EQN R\|v 3 ENTER',
  'REGT'    => 'EQN R\|v 4 ENTER',
  'RMDR'    => '\<+ INTG 3',
  # G13
  'RND'     => '\+> RND',
  'RPN'     => 'MODE 5',
  'RTN'     => '\<+ RTN',
  'R\|^'    => '\+> R\|^',
  'SCI'     => '\<+ DISPLAY 2',
  'SEED'    => '\<+ SEED',
  'SF'      => '\<+ FLAGS 1',
  'SGN'     => '\<+ INTG 1',
  # G14
  'SINH'    => '\<+ HYP SIN',
  'SOLVE'   => '\+> SOLVE',
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
  'x<>'     => '\<+ x\<>',
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

# number keystokes
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
  'e'   => 'e',
  '-'   => '+/-',
  '.'   => '.',
};

# EQN keystokes
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
  ','     => '\<+ ,',                     # \;,
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
  '['     => '\+> [] \.> \BS',
  '\092'  => '\+> BASE 8',                # b
  ']'     => '\+> [] \BS \.>',
  '^'     => 'y^x',
  '_'     => '',
  '\096'  => '\+> BASE 7',                # o
  'a'     => '',
  'b'     => '\+> BASE 8',                # \092
  'c'     => '',
  'd'     => '\+> BASE 5',                # \252
  # 'e'     => 'e',                         # \231
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
  '\Gm'   => '\<+ CONST \.v \.v \.v 4 \BS',             # µ
  'µ'     => '\<+ CONST \.v \.v \.v 4 \BS',             # \Gm
  '\144'  => '',
  '\145'  => '\+> SUM 4 \.< \BS \BS \.>',               # ²
  '²'     => '\+> SUM 4 \.< \BS \BS \.>',               # \145
  '\146'  => '',
  '\147'  => '',
  '\^o'   => '\<+ ->\^oF \.> \BS \BS \BS \.< \BS \.>',  # °
  '°'     => '\<+ ->\^oF \.> \BS \BS \BS \.< \BS \.>',  # \^o
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
  '\231'  => 'e',                           # e
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
  '\|>'   => '\+> STO \CC',
  # additional char
  '³'     => '',
  '#'     => '',
  '{'     => '',
  '|'     => '',
  '}'     => '',
};

# Optimize keystokes
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
                                                    => '\<+ CONST \.v \.v \.v \.v 5',   # \^r\^e
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
  # RCL
  '\+> STO \CC RCL'                                 => '\+> STO',                       # \|>
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
  '\+> [] \.> \BS \+> [] \BS \.>'                   => '\+> [] \.>',                    # []
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
  '() \.> \BS RCL I () \BS \.>'                     => 'RCL (I)',                       # (I)
  # .
  '() \.> \BS RCL J () \BS \.>'                     => 'RCL (J)',                       # (J)
  # +
  '\<+ \x-,\y- 1 \+> \x-,\y- 3 \.< \BS \.>'         => '\<+ \x-,\y- 3',                 # \x-\_w
  '\+> S,\Gs 1 \BS \+> S,\Gs 1 \.< \BS \.>'         => '\+> S,\Gs 1',                   # sx
  '\+> S,\Gs 1 \BS \+> S,\Gs 2 \.< \BS \.>'         => '\+> S,\Gs 2',                   # sy
  '\+> S,\Gs 3 \BS \+> S,\Gs 1 \.< \BS \.>'         => '\+> S,\Gs 3',                   # \Gsx
  '\+> S,\Gs 3 \BS \+> S,\Gs 2 \.< \BS \.>'         => '\+> S,\Gs 4',                   # \Gsy
};

sub constant_keystrokes {
  my $const = shift;
  return exists $tbl_const_seq->{$const}
    ? $tbl_const_seq->{$const}
    : $const;
}

sub instruction_keystrokes {
  my $instr = shift;
  return exists $tbl_instr_seq->{$instr}
    ? $tbl_instr_seq->{$instr}
    : $instr;
}

sub number_keystroke {
  my $digit = shift;
  return $tbl_num_seq->{$digit};
}

sub char_keystrokes {
  my $char = shift;
  return exists $tbl_char_seq->{$char}
    ? $tbl_char_seq->{$char}
    : $char;
}

sub optimize_keystrokes {
  my $original  = shift;
  my $max_depth = scalar split /\s+/, $original;
  return _minimize_keystrokes( $original, 0, $max_depth, );
}

sub _minimize_keystrokes {
  my ( $original, $depth, $max_depth ) = @_;

  return $original
  if $depth >= $max_depth;

  my $best       = $original;
  my $best_count = scalar split /\s+/, $original;

  foreach my $from ( keys %$tbl_opt_seq ) {
    my $to  = $tbl_opt_seq->{$from};
    my $new = $original;

    next unless $new =~ s/\Q$from\E/$to/g;

    my $new_count = scalar split /\s+/, $new;
    next if $new_count > $best_count;

    $new = _minimize_keystrokes( $new, $depth + 1, $max_depth, );

    $new_count = scalar split /\s+/, $new;

    if ( $new_count < $best_count ) {
      $best       = $new;
      $best_count = $new_count;
    }
  }
  return $best;
}

1;
