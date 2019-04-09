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
#   2019-04-09: Initial version created

use strict;
use warnings;

use Getopt::Long;
use DateTime;

# Declaration
my $VERSION = '0.1';
my $version;
my $help;
my $debug;
my $file;
# the next line is only for debugging
#$file = 'C.asm';

Getopt::Long::Configure('bundling');
GetOptions (
  "help"      => \$help,    "h"   => \$help,
  "version"   => \$version, "v"   => \$version,
  "debug"                         => \$debug,
  "file=s"    => \$file,    "f=s" => \$file,
);
# Check command line arguments
&version()    if $version;
&help()       if $help;
$debug        = 0 unless defined $debug;

my %vars = (
);

my %labels = (
);

my $regex_title         = '^title\s+(.*)';
my $regex_model         = '^model\s+(hp35s|35s)';
my $regex_dataseg       = '^dataseg';
my $regex_codeseg       = '^codeseg';
my $regex_line_comment  = ';(.*$)';
my $regex_var           = '\D\w+';
my $regex_label         = '^(\D\w+)\:';
my $regex_start         = '^start\:';
my $regex_end           = '^end\s+start';
my $regex_dbyte         = '\s*(\D\w+)\s+db\s+(\d{1,3}(?:\s*,\s*\d{1,3})*)';
my $regex_char         = '\s*(\D\w+)\s+db\s+[\'"](.+?)[\'"]';

###############################
# Here is the main program 

if (defined $file) {
  open(STDIN, "< $file") or die "Can't open $file : $!";
}

### read the stdin and get the response of the 'show' command
my $response = '';
my $line_no = 0;
my $prg_no = 0;
my $prg_name = '0';
while (<>) {
  $line_no++;
  chomp;
  s/^\s+//;   # trim left
  s/$regex_line_comment//;
  s/\s+$//;   # trim right
  print STDERR "$line_no: skip line\n" if $debug and /^$/;
  next if /^$/;
  
  if (/$regex_title/i) {
    print STDERR "$line_no: TITLE '$1'\n" if $debug;
    next;
  }
  
  if (/$regex_model/i) {
    print STDERR "$line_no: MODEL '$1'\n" if $debug;
    next;
  }

  if (/$regex_dataseg/i) {
    print STDERR "$line_no: DATASEG\n" if $debug;
    while (<>) {
      $line_no++;
      chomp;
      s/^\s+//;   # trim left
      s/$regex_line_comment//;
      s/\s+$//;   # trim right
      print STDERR "$line_no: skip line\n" if $debug and /^$/;
      next if /^$/;

      last if (/$regex_codeseg/i or /$regex_start/i or /$regex_end/i);

      if (/$regex_dbyte/) {
        foreach (split /,/, $2)
        {
        }
        $vars{$1} = $2;
        print STDERR "$line_no: init variable '$1'\n" if $debug;
      }
      elsif (/$regex_char/) {
        $vars{$1} = $2;
        print STDERR "$line_no: init variable '$1'\n" if $debug;
      }
    }
  }
  
  if (/$regex_codeseg/i) {
    print STDERR "$line_no: CODESEG\n" if $debug;
    while (<>) {
      $line_no++;
      chomp;
      s/^\s+//;   # trim left
      s/$regex_line_comment//;
      s/\s+$//;   # trim right
      next if /^$/;

      if (/$regex_start/i)
      {
        print STDERR "$line_no: start\n" if $debug;
        $prg_no = 0;
      }
      if (/$regex_label/i)
      {
        $labels{$1} = $prg_no+1;
        print STDERR "$line_no: label '$1'\n" if $debug and not /$regex_start/;
        next;
      }
      print STDERR "$line_no: end\n" if $debug and /$regex_end/i;
      last if (/$regex_end/i);

      if (/^LBL\s+(\D)/i) {
        print STDERR "$line_no: program $1\n" if $debug;
        $prg_name = $1;
      }
      
      if (/^(EQN\s+)\[($regex_var)\]/i) {
        if (exists $vars{$2}) {
          print STDERR "$line_no: equation '$2'\n" if $debug;
          $_ = $vars{$2};
        }
      }

      $prg_no++;
      print STDERR "$line_no: program number $prg_no\n" if $debug;
      $response .= sprintf("%s%03d\t%s\n", $prg_name, $prg_no, $_);
    }
  }
  
  print STDERR "$line_no: skip line\n" if $debug and /^$/;
}

foreach (keys %labels) {
  my $jumpto = sprintf("%s%03d", $prg_name, $labels{$_});
  print STDERR "label '$_'=$jumpto\n" if $debug;
  $response =~ s/(GTO\s)$_/$1$jumpto/ig;
}

print $response;

###############################
# Here are the subs 

sub version () {
  print "$1 ($VERSION) - by J.Schneider http://www.brickpool.de/\n" if $0 =~ /([^\/\\]+)$/;
  exit 0;
}

sub help () {
  print <<USE;
USAGE:
  c:\> type <asm-file> | perl asm2rpn.pl [options] 1> outfile.rpn 2> outfile.err

VERSION: $VERSION
  Web: http://www.brickpool.de/
  
OPTIONS:
  -h, --help          Print this text
  -v, --version       Prints version
  --debug             Show debug information on STDERR

  --file=<asm-file>:
    Location of asm-file (Default is STDIN)

This script converts an assembler program to HP35s native program code
The output will be sent to STDOUT

USE
  exit 0;
};
