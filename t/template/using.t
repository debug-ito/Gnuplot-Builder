use strict;
use warnings FATAL => "all";
use Test::More;
use Gnuplot::Builder::Template qw(using);

foreach my $case (
    {label => "basic 2D", keys => [qw(x y)]},
    {label => "basic 3D", keys => [qw(x y z)]},
    {label => "basic polar", keys => [qw(t r)]},
    {label => "boxerrorbars (3 cols)", keys => [qw(x y ydelta)]},
    {label => "boxerrorbars (boxwidth != -2)", keys => [qw(x y ydelta xdelta)]}, ## is it possible? maybe we can x_width...
    {label => "boxerrorbars (boxwidth == -2)", keys => [qw(x y ylow yhigh)]},
    {label => "boxerrorbars (5 cols)", keys => [qw(x y ylow yhigh xdelta)]}, ## is it possible? maybe we can x_width...
    {label => "boxes (3 cols)", keys => [qw(x y x_width)]},

    ## boxplot is tricky
    {label => "boxplot (3 cols)", keys => [qw(x y x_width)]},
    {label => "boxplot (4 cols)", keys => [qw(x y x_width boxplot_factor)]},  ## maybe we can ignore this spec...

    {label => "(box)xyerrorbars (4 cols)", keys => [qw(x y xdelta ydelta)]},
    {label => "(box)xyerrorbars (6 cols)", keys => [qw(x y xlow xhigh ylow yhigh)]},
    {label => "candlesticks/financebars", keys => [qw(date open low high close)]},
    {label => "candlesticks (finace with width)", keys => [qw(date open low high close x_width)]},
    {label => "candlesticks", keys => [qw(x box_min whisker_min whisker_high box_high)]},
    {label => "candlesticks (with width)", keys => [qw(x box_min whisker_min whisker_high box_high x_width)]},
    {label => "circles", keys => [qw(x y radius)]},
    {label => "circles (partial)", keys => [qw(x y radius start_angle end_angle)]},
    {label => "ellipses (3 cols)", keys => [qw(x y major_diam)]},
    {label => "ellipses (4 cols)", keys => [qw(x y major_diam minor_diam)]},
    {label => "ellipses (5 cols)", keys => [qw(x y major_diam minor_diam angle)]},
    {label => "filledcurves", keys => [qw(x y1 y2)]},

    #### Ignore this style. "ydelta", "ylow", "yhigh" are enough.
    ## {label => "histograms (errorbars, 2 cols)", keys => [qw(y yerr)]},
    ## {label => "histograms (errorbars, 3 cols)", keys => [qw(y ymin ymax)]},

    {label => "image 2D", keys => [qw(x y value)]},
    {label => "image 3D", keys => [qw(x y z value)]},
    ## rgbimage is subset of rgbalpha
    {label => "rgbalpha 2D", keys => [qw(x y r g b a)]},
    {label => "rgbalpha 3D", keys => [qw(x y z r g b a)]},

    {label => "labels 2D", keys => [qw(x y string)]},
    {label => "labels 3D", keys => [qw(x y z string)]},
    {label => "points 2D + varsize", keys => [qw(x y pointsize)]},
    {label => "points 3D + varsize", keys => [qw(x y z pointsize)]},
    {label => "vectors 2D", keys => [qw(x y xdelta ydelta)]},
    {label => "vectors 2D + vararrow", keys => [qw(x y xdelta ydelta arrowstyle)]},
    {label => "vectors 3D", keys => [qw(x y z xdelta ydelta zdelta)]},
    {label => "vectors 3D + vararrow", keys => [qw(x y z xdelta ydelta zdelta arrowstyle)]},
    {label => "xerrorbars (3 cols)", keys => [qw(x y xdelta)]},
    {label => "xerrorbars (4 cols)", keys => [qw(x y xlow xhigh)]},
    {label => "yerrorbars (3 cols)", keys => [qw(x y ydelta)]},
    {label => "yerrorbars (4 cols)", keys => [qw(x y ylow yhigh)]},
) {
    my @params = map { @$_ } reverse map { [ "-$case->{keys}[$_]" => $_ ] } 0 .. $#{$case->{keys}};
    die "$case->{label}: something is wrong" if !$case->{label} || !@params;
    my $using = using(@params);
    is "$using", join(":", 0 .. $#{$case->{keys}}), "$case->{label}: using string order OK";

    unshift @params, "-linecolor" => 9999;
    $using = using(@params);
    is "$using", join(":", (0 .. $#{$case->{keys}}), 9999), "$case->{label}: using -linecolor is always at the last (as of gnuplot 4.6.6)";
}

done_testing;
