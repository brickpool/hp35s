# ABSTRACT: Convert an assembler program to HP35s native keystrokes

use strict;
use warnings;

our $VERSION = 'v0.5.0';

use Getopt::Long;
use POSIX;
use Data::Dumper;
use Encode;
use File::Basename;

use Parser::HPC; 
use HP35S::Encode::Keystrokes qw(
  constant_keystrokes
  instruction_keystrokes 
  number_keystroke
  char_keystrokes
  optimize_keystrokes
);
use HP35S::Macro qw(
  TIME_PRESSED
  TIME_BTWN_KEYS
  $tbl_char_macro
);
use HP35S::Render qw(
  $tbl_char_plain
  $tbl_char_markdown
  $tbl_char_unicode
);
use HP35S::Instructions qw(
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

# Declaration
my $version;
my $jumpmark;
my $plain;
my $unicode;
my $markdown;
my $shortcut;
my $help;
my $debug;
my $clear;
my $file;
my $encoded;
# the next lines are only for my own test cases
#$file = 'xt\encoding.asm';

Getopt::Long::Configure('bundling');
GetOptions (
  "help"        => \$help,      "h"   => \$help,
  "version"     => \$version,   "v"   => \$version,
  "jumpmark"    => \$jumpmark,  "j"   => \$jumpmark,
  "clear"       => \$clear,     "c"   => \$clear,
  "plain"       => \$plain,     "p"   => \$plain,
  "markdown"    => \$markdown,  "m"   => \$markdown,
  "unicode"     => \$unicode,   "u"   => \$unicode,
  "shortcut"    => \$shortcut,  "s"   => \$shortcut,
  "encoded"     => \$encoded,   "e"   => \$encoded,
  "debug"       => \$debug,
  "file=s"      => \$file,      "f=s" => \$file,
);
# Check command line arguments
&version()    if $version;
&help()       if $help;
$debug    = 0 unless defined $debug;
$shortcut = 1 if $encoded;

my $parser = Parser::HPC->new;

# Constant mapping
my $tbl_const_3graph = {
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

# Instruction mapping
my $tbl_instr_3graph = {
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

my $label = '0';  # start with label '0'
my $lloc = 0;     # logical lines of code
my $out = '';
my $codename = '';
my $response;
my $jump_targets = {};

# Start of the main program 

# option --file
if (defined $file) {
  open(STDIN, '<', $file) or die "Can't open $file : $!";;
}

### read the stdin and get the response
$response = $parser->from_file( \*STDIN );
print STDERR Dumper( $response ) if $debug;

# sort segments in alpabetic order
my @segments = sort keys %{ $response->{segments} };

# predefined equations
my $equations = {
  '??date' => strftime('%Y-%m-%d', localtime),
  '??time' => strftime('%H,%M %S', localtime),
};
# get all equations over all segments
foreach my $seg ( @segments ) {
  next if $response->{segments}->{$seg}->{type} ne 'data';

  defined $response->{segments}->{$seg}->{definitions} or
    warn "no definitions for segment '$seg'\n" and next;

  my $definitions = $response->{segments}->{$seg}->{definitions};

  foreach my $definition ( keys %$definitions ) {
    next if $definitions->{$definition}->{type} ne 'equation';
    defined $definitions->{$definition}->{value} or
      warn "missing 'value' for definition '$definition'\n" and next;

    my $equation = $definitions->{$definition}->{value};
    $equations->{$definition} = $equation;
  }
}

# clear program
CLEAR: {
  $out .= '; \+> CLEAR 3 \.< ENTER'.$/ if $shortcut && $clear;
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
  @register = sort { $sequence->{$a} <=> $sequence->{$b} } @register;

  # build stack
  my @stack = ();
  foreach my $reg ( @register ) {
    my $value = $assignments->{$reg}->{value};
    # t, z, y, x
    SWITCH: for ($reg) {
      /REGT/ && do {
                              # t, z, y, x
        push @stack, $value;  # z, y, x, [v]
        push @stack, 'Rv';    # [v], z, y, x
        last;
      };
      /REGZ/ && do {
                              # t, z, y, x
        push @stack, 'R^';    # z, y, x, t
        push @stack, $value;  # y, x, t, [v]
        push @stack, 'Rv';    # [v], y, x, t
        push @stack, 'Rv';    # t, [v], y, x
        last;
      };
      /REGY/ && do {
                              # t, z, y, x
        push @stack, 'Rv';    # x, t, z, y
        push @stack, 'Rv';    # y, x, t, z
        push @stack, $value;  # x, t, z, [v]
        push @stack, 'R^';    # t, z, [v], x
        last;
      };
      /REGX/ && do {
                              # t, z, y, x
        push @stack, 'Rv';    # x, t, z, y
        push @stack, $value;  # t, z, y, [v]
        last;
      };
      DEFAULT: {
        warn "unknow register $reg\n";
      }
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
    $out .= sprintf("%s%03d\t%s\n", $label, ++$lloc, $_);
  }

  # only one stack segment is supported yet
  last;
}

# start programing
PRGM: {
  $out .= '; \CC \+> PRGM'.$/ if $shortcut;
}

### now handle all code segments
foreach my $seq ( @segments ) {
  # test if it is a code segment
  next unless $response->{segments}->{$seq}->{type} eq 'code';
  $codename = $seq unless $codename;

  # get all statements
  my $statements = $response->{segments}->{$seq}->{statements};
  # get 'source lines of code'
  my $sloc = scalar @$statements;

  # set line number for each statement
  for ( my $line = 0; $line < $sloc; $line++ ) {
    my ($statement, $entry) = %{ $statements->[$line] };
    if ($statement eq 'LBL') {
      $label = $entry->{variable} ;
      $lloc = 0;
    }
    $entry->{line} = sprintf("%s%03d", $label, ++$lloc);
  }

  # generate output for each statement
  for ( my $line = 0; $line < $sloc; $line++ ) {
    my ($statement, $entry) = %{ $statements->[$line] };
    defined $entry->{type} or
      warn "missing 'type' in statement '$statement'\n" and next;

    SWITCH: for ($entry->{type}) {
      /constant/ && do {
        $out .= sprintf_constant_statement( $entry->{line}, $statement );
        last;
      };
      /decimal|binary|octal|hex/ && do {
        $out .= sprintf_number_statement( $entry->{line}, $statement );
        last;
      };
      /vector/ && do {
        $out .= sprintf_vector_statement( $entry->{line}, $statement );
        last;
      };
      /complex/ && do {
        $out .= sprintf_complex_statement( $entry->{line}, $statement );
        last;
      };
      /instruction/ && do {
        my $mnemonic = $statement;
        # instructions without an operand
        if ( grep { $_ eq $mnemonic } @instructions, @functions, @register ) {
          $out .= sprintf_single_instruction( $entry->{line}, $mnemonic );
        }
        # instructions with an address: GTO and XEQ
        elsif ( grep { $_ eq $mnemonic } @with_address ) {
          # absolute address
          if ( defined $entry->{address} ) {
            $out .= sprintf_address_instruction( $entry->{line}, $mnemonic, 
              $entry->{address} );
          }
          # address label
          elsif ( defined $entry->{label} ) {
            $out .= sprintf_label_instruction( $entry->{line}, $mnemonic, 
              $entry->{label}, $seq );
          }
          # unknown operand
          else {
            warn "missing type 'address' or 'label' in instruction "
              . "'$mnemonic'\n";
            next;
          }
        }
        # instructions with a variable: LBL, INPUT, VIEW, STO, ...
        elsif ( grep { $_ eq $mnemonic } @with_variables, @with_indirects ) {
          $out .= sprintf_variable_instruction( $entry->{line}, $mnemonic, 
            $entry->{variable} );
        }
        # instructions with a number: CF, FIX, ...
        elsif ( grep { $_ eq $mnemonic } @with_digits ) {
          $out .= sprintf_number_instruction( $entry->{line}, $mnemonic, 
            $entry->{number} );
        }
        # instructions with an expression: EQN
        elsif ( grep { $_ eq $mnemonic } @expressions ) {
        
          # expression
          if ( defined $entry->{expression} ) {
            $out .= sprintf_expression_instruction( $entry->{line}, $mnemonic, 
              $entry->{expression} );
          }
          # equation
          elsif ( defined $entry->{equation} ) {
            $out .= sprintf_equation_instruction( $entry->{line}, $mnemonic, 
              $entry->{equation} );
          }
          # unknown operand
          else {
            warn "missing type 'expression' or 'equation' in instruction '$mnemonic'\n";
            next;
          }
        }
        # unknown instruction
        else {
          warn "unknown instruction '$mnemonic'\n";
        }
        last;
      };
      # unknown statement
      DEFAULT: {
        warn "unknown statement '$statement'\n";
      }
    }
  }
}

# stop programing
STOP: {
  $out .= '; \CC'.$/ if $shortcut;
}

### print to STDOUT

# option --jumpmark
if ($jumpmark) {
  foreach my $lbl (keys %$jump_targets) {
    $out =~ s/^$lbl/$lbl\*/gm;
  }
}

# option --encoded
if ($encoded) {
  my @lines = $out =~ /^(.*)$/mg;
  unshift @lines, '; \CC \CC \+> PRGM';
  $out = '';
  foreach (@lines) {
    next if /^$/;
    # use only the key strokes
    my $code = my $str = '';
    if (/^(.*?);\s*(.*?)$/) {
      $code = $1;
      $str = $2;
    }
    elsif (/^(.+)$/) {
      $code = $1;
    }
    # map key strokes to hex
    my @enc = ();
    foreach my $key (split /\s+/, $str) {
      if (defined $tbl_char_macro->{$key}) {
        push @enc, $tbl_char_macro->{$key};
      }
      else {
        warn "Encoding error.\n";
      }
    }
    unshift(@enc, ';') if @enc;
    # create new out
    $out.= $code . join(' ', @enc) . "\n";
  }
  UUENCODE: {
    my $str = $out;
    # create header
    if ($codename =~ /^_TEXT$/) {
      my $filename = fileparse($file, qr/\.[^.]*/);
      $out = "begin 644 $filename.mac\n";
    }
    else {
      my $filename = lc $codename;
      $out = "begin 644 $filename.mac\n";
    }
    # use only the key strokes
    $str =~ s/^.*?(?:;\s+|\n)//mg;
    # extending the key codes, in macro key pressed and released
    my $t = 0;
    my $bin = '';
    Encode::_utf8_off $bin;  # bytes
    foreach my $k (split /\s+/, $str) {
      $bin .= $_ = pack 'VVV', hex($k), 1, $t;
      print STDERR unpack('H*', $_), "\n" if $debug;
      $t += TIME_PRESSED;
      $bin .= $_ = pack 'VVV', hex($k), 0, $t;
      print STDERR unpack('H*', $_), "\n" if $debug;
      $t += TIME_BTWN_KEYS;
    }
    # Uuencode the binary string
    $out .= pack 'u', $bin;
    # append trailer
    $out .= 'end';
  }
  #ASCIIENC: {
  #  my $str = $out;
  #  # create header
  #  $out = "%%HP: T(3)A(D)F(.);\n";
  #  # use only the key strokes
  #  $str =~ s/^.*?(?:;\s+|\n)//mg;
  #  # delete all white spaces
  #  $str =~ s/\s+//g;
  #  # wrap after 64 char's
  #  $str =~ s/(.{64})/$1\n/g;
  #  # delete last '\n'
  #  chomp $str;
  #  # quote the ASCII encoded string
  #  $out .= '"'. uc($str) .'"';
  #  # append trailer
  #  $out .= "\n";
  #}
}
# option --unicode
elsif ($unicode) {
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
  # markdown backslash escapes
  $out =~ s/\*/\\\*/g;
  $out =~ s/\[(.*?)\]/\\\[$1\\\]/g;
  # replace tabulator
  $out =~ s/(\w\d\d\d\\\*)\t/$1/gm;
  $out =~ s/(\w\d\d\d)\t/$1  /gm;
  # add 2 spaces to end of line for forcing new line
  $out =~ s/\n/  \n/gm;
  ## code style
  #$out = "<code>\n" . $out . "</code>\n"
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
  $out = qq{%%HP: T(3)A(D)F(.);\n} . $out;
}

print STDOUT $out;

###############################
# Here are the subs 

# constant statement
sub sprintf_constant_statement {
  my $line = shift;
  my $const = shift;
  my $keystrokes = '';

  exists $tbl_const_3graph->{$const} and
    $const = $tbl_const_3graph->{$const};

  defined $shortcut and
    $keystrokes = sprintf("\t\t; %s", constant_keystrokes($const));

  return sprintf("%s\t%s%s\n", $line, $const, $keystrokes);
}

# number statement
sub sprintf_number_statement {
  my $line = shift;
  my $number = shift;
  my $keystrokes = '';

  if ($shortcut) {
    my ($sign, $digits, $exponent, $base) 
      = $number =~ /^(\-?)([\.\dA-F]+)(?:e(\-?[\.\dA-F]+))?([dhob]?)$/;

    # start sequence
    SWITCH: for ($base) {
      /^d/ && do {
        $keystrokes .= sprintf("\t\t; %s", number_keystroke('dec'));
        last;
      };
      /^h/ && do {
        $keystrokes .= sprintf("\t\t; %s", number_keystroke('hex'));
        last;
      };
      /^o/ && do {
        $keystrokes .= sprintf("\t\t; %s", number_keystroke('oct'));
        last;
      };
      /^b/ && do {
        $keystrokes .= sprintf("\t\t; %s", number_keystroke('bin'));
        last;
      };
      DEFAULT: {
        $keystrokes = "\t\t;";
      }
    }

    # sequence for mantissa and exponent
    foreach (split //, $digits) {
      my $key = number_keystroke($_);
      defined $key and
        $keystrokes .= sprintf(" %s", $key);
    }
    if ($sign) {
      $keystrokes .= sprintf(" %s", number_keystroke('-'));
    }
    if ($exponent) {
      $keystrokes .= sprintf(" %s", number_keystroke('e'));
      foreach (split //, $exponent) {
        my $key = number_keystroke($_);
        defined $key and
          $keystrokes .= sprintf(" %s", $key);
      }
    }

    # end sequence
    if ($base) {
      $keystrokes .= sprintf(" %s", number_keystroke($base));
      $keystrokes .= sprintf(" %s", number_keystroke('dec'));
    }
    $keystrokes .= ' ENTER';
  }
  return sprintf("%s\t%s%s\n", $line, $number, $keystrokes);
}

# vector statement
sub sprintf_vector_statement {
  my $line = shift;
  my $vector = shift;
  my $keystrokes = '';

  $vector =~ /\[(\S+)\]/;
  my ($a, $b, $c) = split /,/, $1;
  defined $a and defined $b or
    warn "unknown syntax for vector number '$vector'\n" and return '';

  if ($shortcut) {
    my @numbers = defined $c ? ($a, $b, $c) : ($a, $b);

    # start sequence
    $keystrokes .= "\t\t; \\+> []";
    my $i = 0;
    foreach my $number (@numbers) {
      my ($sign, $digits, $exponent) 
        = $number =~ /^(\-?)([\.\d]+)(?:e(\-?[\.\d]+))?$/;

      # seperator
      $keystrokes .= ' \<+ ,' if $i++;

      # sequence for mantissa and exponent
      foreach (split //, $digits) {
        my $key = number_keystroke($_);
        defined $key and
          $keystrokes .= sprintf(" %s", $key);
      }
      if ($sign) {
        $keystrokes .= sprintf(" %s", number_keystroke('-'));
      }
      if ($exponent) {
        $keystrokes .= sprintf(" %s", number_keystroke('e'));
        foreach (split //, $exponent) {
          my $key = number_keystroke($_);
          defined $key and
            $keystrokes .= sprintf(" %s", $key);
        }
      }
    }
    # end sequence
    $keystrokes .= ' ENTER';
  }

  return sprintf("%s\t%s%s\n", $line, $vector, $keystrokes);
}

# complex statement
sub sprintf_complex_statement {
  my $line = shift;
  my $complex = shift;
  my $keystrokes = '';

  my ($a, $sep, $b) = split /([it])/, $complex;
  defined $a and defined $b or
    warn "unknown syntax for complex number '$complex'\n" and return '';

  $sep =~ s/i/\\im/;
  $sep =~ s/t/\\Gh/;

  if ($shortcut) {
    my @numbers = ($a, $b);

    # start sequence
    $keystrokes = "\t\t;";
    my $i = 0;
    foreach my $number (@numbers) {
      my ($sign, $digits, $exponent) 
        = $number =~ /^(\-?)([\.\d]+)(?:e(\-?[\.\d]+))?$/;

      # seperator
      $keystrokes .= sprintf(" %s", instruction_keystrokes($sep)) if $i++;

      # sequence for mantissa and exponent
      foreach (split //, $digits) {
        my $key = number_keystroke($_);
        defined $key and
          $keystrokes .= sprintf(" %s", $key);
      }
      if ($sign) {
        $keystrokes .= sprintf(" %s", number_keystroke('-'));
      }
      if ($exponent) {
        $keystrokes .= sprintf(" %s", number_keystroke('e'));
        my $key = number_keystroke($_);
        foreach (split //, $exponent) {
          defined $key and
            $keystrokes .= sprintf(" %s", $key);
        }
      }
    }
    # end sequence
    $keystrokes .= ' ENTER';
  }

  return sprintf("%s\t%s%s%s%s\n", $line, $a, $sep, $b, $keystrokes);
}

# instructions without an operand
sub sprintf_single_instruction {
  my $line = shift;
  my $mnemonic = shift;
  my $keystrokes = '';

  exists $tbl_instr_3graph->{$mnemonic} and
    $mnemonic = $tbl_instr_3graph->{$mnemonic};

  defined $shortcut and
    $keystrokes = sprintf("\t\t; %s", instruction_keystrokes($mnemonic));

  # special handling for ENG
  $mnemonic = 'ENG' if $mnemonic eq 'ENG\->';
  return sprintf("%s\t%s%s\n", $line, $mnemonic, $keystrokes);
}

# instructions with absolute address
sub sprintf_address_instruction {
  my $line = shift;
  my $mnemonic = shift;
  my $addr = shift;
  my $keystrokes = '';

  exists $tbl_instr_3graph->{$mnemonic} and
    $mnemonic = $tbl_instr_3graph->{$mnemonic};

  $jump_targets->{$addr} = $addr;
  if ($shortcut) {
    $keystrokes = sprintf("\t; %s ", instruction_keystrokes($mnemonic));
    $keystrokes .= join(' ', split//, $addr);
  }
  # optimization for first addr (e.g. 'A 0 0 1' -> 'A ENTER')
  $keystrokes =~ s/([A-Z]) 0 0 1/$1 ENTER/;
  return sprintf("%s\t%s %s%s\n", $line, $mnemonic, $addr, $keystrokes);
}

# instructions with address label
sub sprintf_label_instruction {
  my $line = shift;
  my $mnemonic = shift;
  my $label = shift;
  my $seq = shift;
  my $keystrokes = '';
  
  defined $response->{labels}->{$label}->{segment} or
    warn "missing 'label' for instruction '$mnemonic'\n" and return '';

  exists $tbl_instr_3graph->{$mnemonic} and
    $mnemonic = $tbl_instr_3graph->{$mnemonic};

  if ( $response->{labels}->{$label}->{type} eq 'near' ) {
    my $pos = $response->{labels}->{$label}->{statement};
    my (undef, $entry) 
      = %{ $response->{segments}->{$seq}->{statements}->[$pos] };
    my $addr = $entry->{line};
    $jump_targets->{$addr} = $addr;
    if ($shortcut) {
      $keystrokes = sprintf("\t; %s ", instruction_keystrokes($mnemonic));
      $keystrokes .= join(' ', split//, $addr);
      # optimization for first addr (e.g. 'A 0 0 1' -> 'A ENTER')
      $keystrokes =~ s/([A-Z]) 0 0 1/$1 ENTER/;
    }
    return sprintf("%s\t%s %s%s\n", $line, $mnemonic, $addr, $keystrokes);
  }
  else {
    warn "far 'label' not supported yet\n";
    my $far = $response->{labels}->{$label}->{segment};
    my $near = $response->{labels}->{$label}->{statement} + 1;
    defined $shortcut and
      $keystrokes = sprintf("\t; %s ...", instruction_keystrokes($mnemonic));
    return sprintf("%s\t%s %s+%03d%s\n", $line, $mnemonic, $far, $near, 
      $keystrokes);
  }
}

# instructions with a variable
sub sprintf_variable_instruction {
  my $line = shift;
  my $mnemonic = shift;
  my $variable = shift;
  my $keystrokes = '';

  defined $variable or
    warn "missing type 'variable' in instruction '$mnemonic'\n" and return '';

  exists $tbl_instr_3graph->{$mnemonic} and
    $mnemonic = $tbl_instr_3graph->{$mnemonic};

  my $space = $variable =~ /\([IJ]\)/ ? '' : ' ';   # indirects have no space
  defined $shortcut and
    $keystrokes = sprintf("\t\t; %s %s", instruction_keystrokes($mnemonic), 
      $variable);
  return sprintf("%s\t%s%s%s%s\n", $line, $mnemonic, $space, $variable, 
    $keystrokes);
}

sub sprintf_number_instruction {
  my $line = shift;
  my $mnemonic = shift;
  my $number = shift;
  my $keystrokes = '';

  defined $number or
    warn "missing type 'number' in instruction '$mnemonic'\n" and return '';

  exists $tbl_instr_3graph->{$mnemonic} and
    $mnemonic = $tbl_instr_3graph->{$mnemonic};

  my $digits = $number < 10 ? $number : sprintf(". %d", $number % 10);
  defined $shortcut and
    $keystrokes = sprintf("\t\t; %s %s", instruction_keystrokes($mnemonic), 
      $digits);
  return sprintf("%s\t%s %s%s\n", $line, $mnemonic, $number, $keystrokes);
}

sub sprintf_expression_instruction {
  my $line = shift;
  my $mnemonic = shift;
  my $equation = shift;
  my $keystrokes = '';
  my $ret = '';
  
  exists $tbl_instr_3graph->{$mnemonic} and
    $mnemonic = $tbl_instr_3graph->{$mnemonic};

  $equation =~ s/(?<!\\O)\//\\:-/;  # '/' => '\:-'
  $equation =~ s/\*/\\\.x/;         # '*' => '\.x'
#  $equation =~ s/e/\\231/;         # 'e' => '\231'
#  $equation =~ s/i/\\im/;          # 'i' to '\im'

  if ($shortcut) {
 
    my $state = 'normal';
    my $char = '';
    foreach (split //, $equation)
    {
      $char .= $_;
      SWITCH: {
        $state =~ /normal/ && do {
          if (/\\/) {
            $state = 'start';
            $char = '\\';
          }
          else {
            my $seq = char_keystrokes($char);
            $keystrokes .= sprintf(" %s", $seq) if length $seq > 0;
            $char = '';
          }
          last;
        };
        $state =~ /start/ && do {
          if (/\\/) {
            $state = 'normal';
            my $seq = char_keystrokes($char);
            $keystrokes .= sprintf(" %s", $seq) if length $seq > 0;
            $char = '';
          }
          elsif (/\d/) {
            $state = 'middle';
          }
          else {
            $state = 'end';
          }
          last;
        };
        $state =~ /middle/ && do {
          if (/\d/) {
            $state = 'end';
          }
          else {
            $state = 'unknown';
          }
          last;
        };
        $state =~ /end/ && do {
          if (/\\/) {
            $state = 'unknown';
          }
          else {
            $state = 'normal';
            my $seq = char_keystrokes($char);
            $keystrokes .= sprintf(" %s", $seq) if length $seq > 0;
            $char = '';
          }
          last;
        };
      }
    }

    # optimize key strokes
    $keystrokes = optimize_keystrokes($keystrokes);
    # special case for '[]'
    my ($a1, $a2) = map quotemeta, 
      ' \+> [] \.> \BS', 
      ' \+> [] \BS \.>';
    while ($keystrokes =~ /^(.*?)$a1(.*?)$a2(.*?)$/) {
      $keystrokes = $1.' \+> []'.$2.' \.>'.$3;
    };

    $ret = sprintf("; EQN%s ENTER\n", $keystrokes);
  }
  $ret .= sprintf("%s\t%s %s\n", $line, $mnemonic, $equation);
  return $ret;
}
            
sub sprintf_equation_instruction {
  my $line = shift;
  my $mnemonic = shift;
  my $definition = shift;

  defined $equations->{$definition} or
    warn "missing 'equation' for instruction '$mnemonic'\n" and return '';

  return sprintf_expression_instruction($line, $mnemonic, 
    $equations->{$definition});
}

sub version () {
  print "$1 ($VERSION) - by J.Schneider http://www.brickpool.de/\n" 
    if $0 =~ /([^\/\\]+)$/;
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
  -c, --clear         Prints keystrokes to delete the program memory
  -p, --plain         Output as Plain text (7-bit ASCII)
  -m, --markdown      Output as Markdown (inline HTML 5)
  -u, --unicode       Output as Unicode (UTF-8)
  -s, --shortcut      Output shortcut keys as comment
  -e, --encoded       Output key codes as Macros (UU Encoding)
  --debug             Show debug information on STDERR

  --file=<asm-file>:
    Location of asm-file (Default is STDIN)

This script converts an assembler program to HP35s native program code
The output will be sent to STDOUT

USE
  exit 0;
};
