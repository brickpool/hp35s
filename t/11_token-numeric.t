use strict;
use warnings;

use Test::More;
use Test::Exception;
use Parser::HPC;

subtest 'binary token' => sub {
  for my $source ( qw(0b 1b 101b) ) {
    my $parser = Parser::HPC->new(toplevel => 'token_binary');
    is( $parser->from_string("$source\n"), $source, "$source is accepted" );
  }

  for my $source ( qw(2b 102b) ) {
    my $parser = Parser::HPC->new(toplevel => 'token_binary');
    dies_ok { $parser->from_string("$source\n") } "$source is rejected";
  }
};

subtest 'octal token' => sub {
  for my $source ( qw(0o 7o 123o) ) {
    my $parser = Parser::HPC->new(toplevel => 'token_octal');
    is( $parser->from_string("$source\n"), $source, "$source is accepted" );
  }

  for my $source ( qw(8o 128o) ) {
    my $parser = Parser::HPC->new(toplevel => 'token_octal');
    dies_ok { $parser->from_string("$source\n") } "$source is rejected";
  }
};

subtest 'decimal token' => sub {
  for my $source ( qw(0d 12d -12d) ) {
    my $parser = Parser::HPC->new(toplevel => 'token_decimal');
    is( $parser->from_string("$source\n"), $source, "$source is accepted" );
  }

  for my $source ( qw(12 1.2d) ) {
    my $parser = Parser::HPC->new(toplevel => 'token_decimal');
    dies_ok { $parser->from_string("$source\n") } "$source is rejected";
  }
};

subtest 'hex token' => sub {
  for my $source ( qw(0h 17h FFh) ) {
    my $parser = Parser::HPC->new(toplevel => 'token_hex');
    is( $parser->from_string("$source\n"), $source, "$source is accepted" );
  }

  for my $source ( qw(Gh ffh) ) {
    my $parser = Parser::HPC->new(toplevel => 'token_hex');
    dies_ok { $parser->from_string("$source\n") } "$source is rejected";
  }
};

done_testing;
