use strict;
use warnings FATAL => "all";
use Test::More;
use Gnuplot::Builder::Template qw(using);

foreach my $case (
    ## linecolor is always at the last of using spec (as of gnuplot
    ## 4.6.6, though), so using() func doesn't care about it.

    {label => "basic 2D", keys => [qw(x y)]},
    {label => "basic 3D", keys => [qw(x y z)]},
    {label => "boxerrorbars (3 cols)", keys => [qw(x y ydelta)]},
    {label => "boxerrorbars (boxwidth != -2)", keys => [qw(x y ydelta xdelta)]},
    {label => "boxerrorbars (boxwidth == -2)", keys => [qw(x y ylow yhigh)]},
    {label => "boxerrorbars (5 cols)", keys => [qw(x y ylow yhigh xdelta)]},
    {label => "boxes (3 cols)", keys => [qw(x y x_width)]},

    ## boxplot is tricky
    {lable => "boxplot (3 cols)", keys => [qw(x y x_width)]},
    {label => "boxplot (4 cols)", keys => [qw(x y x_width boxplot_factor)]},  ## maybe we can ignore this spec...

    {label => "boxxyerrorbars", keys => []},  ## ここから
    
    {label => "points 2d + varsize", keys => [qw(x y pointsize)]},
    {label => "points 3d + varsize", keys => [qw(x y z pointsize)]},
) {
    my @params = map { @$_ } reverse map { [ "-$case->{keys}[$_]" => $_ ] } 0 .. $#{$case->{keys}};
    my $using = using(@params);
    is "$using", join(":", 0 .. $#{$case->{keys}}), "$case->{label}: using string order OK";
}

done_testing;
