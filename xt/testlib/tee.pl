use strict;
use warnings;

my $filename = shift @ARGV;
open my $file, ">", $filename or die "Cannot open $filename: $!";

while(defined(my $line = <STDIN>)) {
    print $line;
    print $file $line;
}
close $file;
