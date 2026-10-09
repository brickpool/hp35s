use strict;
use warnings;

use File::Find;
use Test::More;

my @modules;
find(
  {
    no_chdir => 1,
    wanted   => sub {
      return unless $File::Find::name =~ /\.pm\z/;
      my $module = $File::Find::name;
      $module =~ s{\\}{/}g;
      $module =~ s{^lib/}{};
      $module =~ s{\.pm\z}{};
      $module =~ s{/}{::}g;
      push @modules, $module;
    },
  },
  'lib',
);

use_ok($_) for sort @modules;

done_testing;