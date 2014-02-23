use strict;
use warnings;
use Test::More;
use Test::Identity;
use Gnuplot::Builder::Dataset;

{
    note("--- example: parse options");

    my $options_script = <<OPT;
  -axes
  title = "Weight [kg]"
  with  = lines
  lw    = 2

matrix

# volatile

OPT

    {
        my $dataset = Gnuplot::Builder::Dataset->new('cos(x)');
        identical $dataset->set_option($options_script), $dataset, "set_option() returns the dataset";
        is $dataset->to_string, q{cos(x) title "Weight [kg]" with lines lw 2 matrix}, "set_option() OK";
        $dataset->set_option(axes => "x1y2");
        is $dataset->to_string, q{cos(x) axes x1y2 title "Weight [kg]" with lines lw 2 matrix}, "axes remains the original position";
    }

    {
        my $dataset = Gnuplot::Builder::Dataset->new('sin(x)');
        identical $dataset->setq_option($options_script), $dataset, "setq_option() returns the dataset";
        is $dataset->to_string(), q{cos(x) title '"Weight [kg]"' with 'lines' lw '2' matrix ''}, "setq_option() OK";
        $dataset->setq_option(axes => 'x1y2');
        is $dataset->to_string(), q{cos(x) axes 'x1y2' title '"Weight [kg]"' with 'lines' lw '2' matrix ''}, "axes remains the original position";
    }

}

{
    note("--- multiple occurrences of the same name");
    my $options = <<OPT;
 using = 1:4

using = 2:3:5
OPT
    my $dataset = Gnuplot::Builder::Dataset->new('f(x)');
    $dataset->set_option($options);
    is $dataset->to_string(), q{f(x) using 1:4}, "the first occurrence is used in to_string()";
    is $dataset->get_option("using"), "1:3", "the first occurrence is used in get_option()";
}

done_testing;