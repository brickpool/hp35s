package HP35s::Vocabulary;
# ABSTRACT: Assembler vocabulary for the HP35S calculator

use strict;
use warnings;

use version;
our $VERSION = version->declare('v0.5.0');

use Exporter 'import';
our @EXPORT_OK = qw(
  @constants
  @instructions
  @functions
  @expressions
  @with_address
  @with_digits
  @with_variables
  @with_indirects
  @register
  instruction_kind
);

our @constants = (
  'pi',   # Pi (3.1416)
  'i',    # Im (0.0000i1.0000)
  
  'c',    # Speed of light in vacuum
  'g',    # Standard acceleration of gravity
  'G',    # Newtonian constant of gravitation
  'Vm',   # Molar volume of ideal gas
  'NA',   # Avogadro constant
  'Rb',   # Rydberg constant
  'eV',   # Elementary charge
  'me',   # Electron mass
  'mp',   # Proton mass
  'mn',   # Neutron mass
  'mu',   # Muon mass
  'k',    # Boltzmann constant
  'h',    # Planck constant
  'hbar', # Planck constant over 2 pi
  'Ph0',  # Magnetic flux quantum
  'a0',   # Bohr radius
  'e0',   # Electric constant
  'R',    # Molar gas constant
  'F',    # Faraday constant
  'u',    # Atomic mass constant
  'u0',   # Magnetic constant
  'uB',   # Bohr magneton
  'uN',   # Nuclear magneton
  'up',   # Proton magnetic moment
  'ue',   # Electron magnetic moment
  'un',   # Neutron magnetic moment
  'uu',   # Muon magnetic moment
  're',   # Classical electron radius
  'Z0',   # Characteristic impendence of vacuum
  'lc',   # Compton wavelength
  'lcn',  # Neutron Compton wavelength
  'lcp',  # Proton Compton wavelength
  'a',    # Fine structure constant
  'z',    # Stefan-Boltzmann constant
  't',    # Celsius temperature
  'atm',  # Standard atmosphere
  'gp',   # Proton gyromagnetic ratio
  'C1',   # First radiation constant
  'C2',   # Second radiation constant
  'G0',   # Conductance quantum
  'e',    # The base number of natural logarithm
);

our @instructions = (
  # G1
  '+/-', '+', '-', '*', '/',
  # G2
  '1/x', '10^x', '%', '%CHG', 'Z+', 'Z-',
  # G3
  'Zx', 'Zx^2', 'Zxy', 'Zy', 'Zy^2', 'zx', 'zy',
  # G4
  'ALG', 'ALL', 'AND',
  # G5
  'b', 'BIN', '/c',
  # G6
  'CLZ', 'CLx', 'CLVARS', 'CLSTK', 'nCr', 'DEC', 'DEG',
  # G7
  '<-ENG', 'ENG->', 'ENTER', 'e^x',
  # G8
  'FP', 'GRAD', 'HEX',
  # G9
  '->HMS', 'HMS->', '->IN', 'INT/', 'INTG',
  # G10
  'IP', '->KG', '->KM', '->L', 'LASTx', '->LB', 'LN', 'LOG', 'm',
  # G11
  '->MILE', 'n', 'NAND', 'NOR', 'NOT', 'OCT', 'OR', 'nPr', 'PSE',
  # G12
  'r', 'rta', 'RAD', '->RAD', 'RADIX,', 'RADIX.', 'RANDOM', 'RMDR',
  # G13
  'RND', 'RPN', 'RTN', 'Rv', 'R^', 'SEED', 'SGN',
  # G14
  'STOP',
  # G15
  'sx', 'sy', 'x^2', 'sqrt', 'xroot', '\x-', '\x^', '!',
  # G16
  '\x-w', 'x<>y', 'x!=y?', 'x<=y?', 'x<y?', 'x>y?', 'x>=y?',
  # G17
  'x=y?', 'x!=0?', 'x<=0?', 'x<0?', 'x>0?', 'x>=0?', 'x=0?', 'XOR',
  # G18
  'xiy', 'x+yi', '\y-', '\y^', 'y^x',
);

our @functions = (
  # G2
#  'INV',
  # G4
  'ABS', 'ACOS', 'ACOSH',
#  'ALOG',
  'ARG', 'ASIN', 'ASINH', 'ATAN',
  # G5
  'ATANH', '->°C',
  # G6
  '->CM', 'COS', 'COSH', '->DEG',
  # G8
#  'EXP',
  '->°F', '->GAL',
  # G9
#  'IDIV', 'INV',
  # G12
  'RMDR',
  # G14
  'SIN', 'SINH',
#  'SQ', 'SQRT',
  # G15
  'TAN', 'TANH',
  # G16
#  'XROOT',
);

our @expressions = (
  # G7
  'eqn',
);

our @with_address = (
  # G8
  'GTO',
  # G15
  'XEQ',
);

our @with_digits = (
  # G5
  'CF',
  # G7
  'ENG',
  # G8
  'FIX', 'FS?',
  # G13
  'SCI', 'SF',
);

our @with_variables = (
  # G9
  'INPUT',  # HP35s bug -> INVALID (I)
  # G10
  'LBL',
);

# 14-22
our @with_indirects = (
  # G3
  '$FN_d',
  # G7
  'DSE',
  # G8
  'FN=',
  # G10
  'ISG',
  # G12
  'RCL', 'RCL+', 'RCL-', 'RCL*', 'RCL/',
  # G14
  'SOLVE', 'STO', 'STO+', 'STO-', 'STO*', 'STO/',
  # G15
  'VIEW',
  # G16
  'x<>',
);

our @register = (
  'REGX', 'REGY', 'REGZ', 'REGT',
);

sub instruction_kind {
  my $mnemonic = shift;

  return 'plain'
    if grep { $_ eq $mnemonic } @instructions, @functions, @register;

  return 'address'
    if grep { $_ eq $mnemonic } @with_address;

  return 'variable'
    if grep { $_ eq $mnemonic } @with_variables;

  return 'digit'
    if grep { $_ eq $mnemonic } @with_digits;

  return 'indirect'
    if grep { $_ eq $mnemonic } @with_indirects;

  return 'expression'
    if grep { $_ eq $mnemonic } @expressions;

  return;
}

1;