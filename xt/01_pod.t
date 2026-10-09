use strict;
use Test::More;

eval "use Test::Pod";
plan skip_all => "Test::Pod required for testing POD" if $@;

my @poddirs = qw( blib );
my @podfiles = all_pod_files( @poddirs );
push @podfiles, 'README.pod', 'bin/asm2hpc.pl';

all_pod_files_ok( @podfiles );