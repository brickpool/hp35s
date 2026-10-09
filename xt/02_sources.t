use strict;
use warnings;

use Test::More;
use Parser::HPC;
use lib 't/lib';
use FrontendTest qw( run_frontend );

my @sources = sort glob 'xt/*.asm';
plan skip_all => 'No assembler sources found in xt' unless @sources;

for my $file ( @sources ) {
  subtest $file => sub {
    open my $handle, '<', $file or die "Cannot open $file: $!";
    my $source = do { local $/; <$handle> };
    close $handle or die "Cannot close $file: $!";

    my @messages;
    {
      local $SIG{__WARN__} = sub { push @messages, @_ };
      Parser::HPC->new->from_string($source);
    }
    my $messages = join '', @messages;
    my ($status, $output, $errors) = run_frontend($source);
    is( $status, 0, 'frontend succeeds' );
    is( $errors, $messages, 'only expected DISPLAY messages on STDERR' );
    like( $output, qr/\A%%HP:/, 'produces an HP listing' );
  };
}

done_testing;
