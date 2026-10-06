package HP35S::Charset;
# ABSTRACT: Character set mapping for the HP35S calculator

use strict;
use warnings;

our $VERSION = 'v0.5.0';

use Exporter 'import';
our @EXPORT_OK = qw(
  $character
);

# EQN character
our $character = {
  '\^c'   => '02',  # Constant 'lamda c'
  '\^e'   => '03',  # Constant 'e'
  '\^g'   => '04',  # Constant 'g'
  '\^h'   => '05',  # Constant 'h'
  '\^m'   => '06',  # Constant 'me'
  '\^n'   => '07',  # Constant 'mn'
  '\^p'   => '08',  # Constant 'mp'
  '\^r'   => '09',  # Constant 're'
  '\^t'   => '0a',  # Constant 'atm'
  '\015'  => '0f',  # Constant 'NA'
  '\016'  => '10',  # Constant 'c'
  '\017'  => '11',  # Constant 'F'
  '\018'  => '12',  # Constant 'G'
  '\^k'   => '13',  # Constant 'k'
  '\020'  => '14',  # Constant 'R'
  '\021'  => '15',  # Constant 'G0'
  '\023'  => '17',  # Constant 'h-bar'
  '\024'  => '18',  # Constant 't'
  '\Ga'   => '19',  # Constant 'alpha'
  '\Gl'   => '1a',  # Constant 'lamda c'
  '\O/'   => '1b',  # Constant 'Phi 0'
  '\Gg'   => '1c',  # Constant 'gamma p'
  '\oo'   => '1e',  # Constant 'R infinity'
  '\Ge'   => '1f',  # Constant 'epsilon 0'
  ' '     => '20',  # Space
  '!'     => '21',  # Factorial symbol
  '%'     => '25',  # Percent symbol '%CHG'
  '\^-'   => '26',  # Sign symbol '+/-'
  '('     => '28',  # Function bracket
  ')'     => '29',  # Function bracket
  '+'     => '2b',  # Addition sign
  '-'     => '2d',  # Substraction sign
  '0'     => '30',  # Number '0'
  '1'     => '31',  # Number '1'
  '2'     => '32',  # Number '2'
  '3'     => '33',  # Number '3'
  '4'     => '34',  # Number '4'
  '5'     => '35',  # Number '5'
  '6'     => '36',  # Number '6'
  '7'     => '37',  # Number '7'
  '8'     => '38',  # Number '8'
  '9'     => '39',  # Number '9'
  '='     => '3d',  # Equal symbol
  'A'     => '41',  # Variable 'A'
  'B'     => '42',  # Variable 'B'
  'C'     => '43',  # Variable 'C'
  'D'     => '44',  # Variable 'D'
  'E'     => '45',  # Variable 'E'
  'F'     => '46',  # Variable 'F'
  'G'     => '47',  # Variable 'G'
  'H'     => '48',  # Variable 'H'
  'I'     => '49',  # Variable 'I'
  'J'     => '4a',  # Variable 'J'
  'K'     => '4b',  # Variable 'K'
  'L'     => '4c',  # Variable 'L'
  'M'     => '4d',  # Variable 'M'
  'N'     => '4e',  # Variable 'N'
  'O'     => '4f',  # Variable 'O'
  'P'     => '50',  # Variable 'P'
  'Q'     => '51',  # Variable 'Q'
  'R'     => '52',  # Variable 'R'
  'S'     => '53',  # Variable 'S'
  'T'     => '54',  # Variable 'T'
  'U'     => '55',  # Variable 'U'
  'V'     => '56',  # Variable 'V'
  'W'     => '57',  # Variable 'W'
  'X'     => '58',  # Variable 'X'
  'Y'     => '59',  # Variable 'Y'
  'Z'     => '5a',  # Variable 'Z'
  '['     => '5b',  # Vector bracket
  '\092'  => '5c',  # Base binary 'b'
  'b'     => '5c',
  ']'     => '5d',  # Vector bracket
  '^'     => '5e',  # Exponent 'y^x'
  '\096'  => '60',  # Base octal 'o'
  'o'     => '60',
  '\_b'   => '7b',  # Linear regression 'b'
  '\125'  => '7d',  # Standard Deviation 's'
  's'     => '7d',
  '\128'  => '80',  # Summation statistics 'n'
  'n'     => '80',
  '\:-'   => '81',  # Division sign
  '/'     => '81',
  '\.x'   => '82',  # Multiplication sign
  '*'     => '82',
  '\GS'   => '85',  # Summation statistics 'Sigma x'
  '\pi'   => '87',  # Greek small 'pi'
  '\_y'   => '8c',  # Standard Deviation 'sigma y'
  'y'     => '8c',
  '\->'   => '8d',  # Unit Conversion '->l'
  '\_x'   => '8e',  # Standard Deviation 'sigma x'
  'x'     => '8e',
  '\Gm'   => '8f',  # Constant 'µµ'
  'µ'     => '8f',
  '\145'  => '91',  # Summation statistics 'Sigma x^2'
  '²'     => '91',
  '\^o'   => '94',  # Degree '->°F'
  '°'     => '94',
  '\157'  => '9d',  # Constant 'sigma'
  '\Gh'   => '9e',  # Complex small 'theta'
  '\167'  => 'a7',  # Constant 'atm'
  '\171'  => 'ab',  # Linear regression 'r'
  'r'     => 'ab',
  '\Gs'   => 'ae',  # Standard Deviation 'sigma x'
  '\x-'   => 'af',  # Mean 'x-bar'
  '\y-'   => 'b0',  # Mean 'y-bar'
  '\x^'   => 'b1',  # Linear estimation 'x-hat'
  '\y^'   => 'b2',  # Linear estimation 'y-hat'
  '\179'  => 'b3',  # Linear regression 'm'
  'm'     => 'b3',
  '\^1'   => 'b8',  # Constant 'C1'
  '\^2'   => 'b9',  # Constant 'C2'
  '\_w'   => 'c1',  # Mean 'x-bar w'
  'w'     => 'c1',
  '\^B'   => 'c5',  # Constant 'µB'
  '\^C'   => 'c6',  # Constant 'C1'
  '\^G'   => 'ca',  # Constant 'G0'
  '\^N'   => 'd1',  # Constant 'NA'
  '\^a'   => 'd8',  # Constant 'a0'
  '\^u'   => 'e3',  # Constant 'u'
  '\231'  => 'e7',  # Exponent 'E'
  'e'     => 'e7',
  '\235'  => 'eb',  # Base hexadecimal 'h'
  'h'     => 'eb',
  '\im'   => 'ec',  # Complex script small 'i'
  'i'     => 'ec',
  '\^R'   => 'ef',  # Constant 'R infinity'
  '\^V'   => 'f3',  # Constant 'Vm'
  '\^Z'   => 'f7',  # Constant 'Z0'
  '\252'  => 'fc',  # Base decimal 'd'
  'd'     => 'fc',
  '\;,'   => 'fd',  # comma ',' in function
  ','     => 'fd',
  '\|>'   => 'ff',  # 'STO' in mode algebraic
};

1;
