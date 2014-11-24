use strict;
use warnings FATAL => "all";
use Test::More;

foreach my $case (
    {label => "lines 2d", keys => [qw(x y)]},
    {label => "lines 3d", keys => [qw(x y z)]},
    {label => "points 2d", keys => [qw(x y)]},
    {label => "points 3d", keys => [qw(x y z)]},
    {label => "points 2d + varsize", keys => [qw(x y pointsize)]},
    {label => "points 3d + varsize", keys => [qw(x y z pointsize)]},
    {label => ""}
) {
    ;
}

done_testing;
