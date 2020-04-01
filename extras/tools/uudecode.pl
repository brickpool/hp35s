#!/usr/bin/perl
# uudecode in perl: from the Programming Perl book
# usage: uudecode.pl file-with-uuencoded-data.uu
#
$_ = <> until ($mode,$file) = /^begin\s*(\d*)\s*(\S*)/;
open(OUT,"> $file") if $file ne "";
binmode(OUT);
while (<>) {
    last if /^end/;
    next if /[a-z]/;
    next unless int((((ord() - 32) & 077) + 2) / 3) ==
                int(length() / 4);
    print OUT unpack "u", $_;
}
chmod oct $mode, $file;
print STDERR "OK: wrote file $file\n"