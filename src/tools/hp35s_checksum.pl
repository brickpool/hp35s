# HP-35s Checksum: Tugdual, Museum of HP Calculators
# https://www.hpmuseum.org/forum/thread-3041-post-26925.html
# usage: hp35s_checksum.pl byte-stream-with-opcodes.raw
#
# Note: the calculation doesn't yet include strings or constant values.

use autodie;

my ($infile) = @ARGV;
open my $in, '<:raw', $infile;

#read hole file as a binary string
my $binary = '';
while (1) {
  my $success = read $in, $binary, 128, length($binary);
  die $! unless defined $success;
  last unless $success;
}
close $in;

# The check sum algorithm is using 6 magic values:
my @magics = (
  0x1021,
  0x1231,
  0x3331,
  0x0373,
  0x3730,
  0x4363,
);

# Each program start with opcode "0x01, 0x01..0x1a, 0x7b"
# - convert the binary into a hex string
# - separate each hex string into programs
my @programs = unpack('H*', $binary) =~ m/[[:xdigit:]]*?(?:01[01][\d,a]7b)/g;

# The emulation file reverse the program order
foreach (reverse @programs) {
  my $lbl;
  my @checksums = ();

  # Each instruction is stored into a block of 3 bytes (= 6 hex digits = 6 nibbles)
  my @instructions = m/[[:xdigit:]]{6}/g;

  # The emulation file reverse the order of instructions
  foreach (reverse @instructions) {
    # get the identifier of the 'LBL' instruction
    $lbl = chr(hex(unpack('x2 A2 x2')) + ord('A')-1) unless $lbl;
  
    # Let's translate each block into 6 nibbles
    my @nibbles = unpack '(A)6';
  
    # Now we associate a magic number to each nibble in the reverse order
    @nibbles = reverse @nibbles;
    push @checksums, 0;
    my @values = (0) x @nibbles;
    for (my $i = 0; $i < @nibbles; $i++) {
      # Each nibble has four bits b0, b1, b2, b3
      for (my $j = 0; $j < 4; $j++) {
        # For a nibble, we calculate 'value = (b0*magic) xor (2*b1*magic) xor (4*b2*magic) xor (8*b3*magic)'
        $values[$i] ^= ((1 << $j) & hex $nibbles[$i]) * $magics[$i];
      }
    }
    # Now we calculate value[1] xor value[2] xor value[3] xor value[4] xor value[5] xor value[6]
    $checksums[-1] ^= $_ for @values;
  }

  if ($lbl) {
    # We sum with the value found previously
    my $crc = 0;
    $crc += $_ for @checksums;
    # The 35s is dropping values above 4 digits and this is how we achieve the result
    $crc &= 0xffff;
    
    # Source lines of code
    my $sloc = @checksums;

    # Displays label, length of the program in bytes and the checksum.
    printf "LBL %s\n", $lbl;
    printf "LN=%d\n", $sloc * 3;
    printf "CK=%04X\n", $crc;
  }
}
