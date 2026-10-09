package HP35s::Render;
# ABSTRACT: Render mappings for the HP35S calculator

use strict;
use warnings;

use version;
our $VERSION = version->declare('v0.5.0');

use Exporter 'import';
our @EXPORT_OK = qw(
  $tbl_const_3graph
  $tbl_instr_3graph
  $tbl_char_plain
  $tbl_char_markdown
  $tbl_char_unicode
);

our $tbl_const_3graph = {
  'i'   => '\im',
  'pi'  => '\pi',
  'c'   => '\016',
  'g'   => '\^g',
  'G'   => '\018',
  'Vm'  => '\^V\^m',
  'NA'  => '\^N\015',
  'Rb'  => '\^R\oo',
  'eV'  => '\^e\^V',
  'me'  => '\^m\^e',
  'mp'  => '\^m\^p',
  'mn'  => '\^m\^n',
  'mu'  => '\^m\Gm',
  'k'   => '\^k',
  'h'   => '\^h',
  '\h-' => '\023',
  'Ph0' => '\O/\021',
  'a0'  => '\^a\021',
  'e0'  => '\Ge\021',
  'R'   => '\020',
  'F'   => '\017',
  'u'   => '\^u',
  'u0'  => '\Gm\021',
  'uB'  => '\Gm\^B',
  'uN'  => '\Gm\^N',
  'up'  => '\Gm\^p',
  'ue'  => '\Gm\^e',
  'un'  => '\Gm\^n',
  'uu'  => '\Gm\Gm',
  're'  => '\^r\^e',
  'Z0'  => '\^Z\021',
  'lc'  => '\Gl\^c',
  'lcn' => '\Gl\^c\^n',
  'lcp' => '\Gl\^c\^p',
  'a'   => '\Ga',
  'z'   => '\157',
  't'   => '\024',
  'atm' => '\167\^t\^m',
  'gp'  => '\Gg\^p',
  'C1'  => '\^C\^1',
  'C2'  => '\^C\^2',
  'G0'  => '\^G\021',
  'e'   => '\^e',
};

our $tbl_instr_3graph = {
  # G1
  '*'     => '\.x',
  '/'     => '\:-',
  # G2
  '10^x'  => '10\^x',
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
  'xiy'   => 'x\imy',
#  'x+yi'  => 'x+y\im', only mode ALG
  'y^x'   => 'y\^x',
};

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
use constant _ymacr     => "\N{U+0233}";
use constant _circ      => "\N{U+0302}";
use constant _ycirc     => "\N{U+0177}";
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
use constant _lg        => "\N{U+2276}";

# plaintext mapping
our $tbl_char_plain = {
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
  '\<>'   => '<>'
};

# Markdown mapping
our $tbl_char_markdown = {
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
  '\<>'   => '&lg;'
};

# Unicode mapping
our $tbl_char_unicode = {
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
  '\Gm'   => 'µ',
  '\145'  => _sup2,
  '\^o'   => '°',
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
  '\<>'   => _lg,
};

1;
