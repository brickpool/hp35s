#!/usr/bin/perl
use HpcParser;
use Data::Dumper;

use strict;
use warnings;

my $parser = HpcParser->new;

print Dumper(
  $parser->from_file( \*DATA )
);







__DATA__
; Example
MODEL P35S          ; actualy only HP35s is permitted

SEGMENT STACK
  REGX SET 1.0
ENDS

SEGMENT DATA
  str EQU '123'     ; string
  i   EQU 4         ; integer
  j   EQU -5        ; integer
  f   EQU 6.7       ; float
ENDS

SEGMENT main_A CODE ; Body of program goes here
start:
  LBL A
  GOTO A014
  GOTO return
  FS? 1
  RADIX.
  +
  +/-
  Z+
  Zx
  1.0
  Z
  R^
  Rv
  EQN '1+2+3'       ; 1+2+3=6
  EQN str
  XOR
  VIEW A
return:
  RTN
ENDS main_A

SEGMENT sub_B CODE
  LBL B
  INPUT J
  x<>(I)
nop:
  RTN
ENDS sub_B

END main            ; program entry point
