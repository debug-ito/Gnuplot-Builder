use strict;
use warnings;
use Test::More;
use Test::Identity;
use Gnuplot::Builder::Dataset;

{
    note("--- params_string()");
    my $builder = Gnuplot::Builder::Dataset->new;
    $builder->set_source("sin(x)");
    $builder->setq_option(title => 'hogehoge');
    $builder->set_option(with => "linespoints");
    is $builder->params_string, "sin(x) title 'hogehoge' with linespoints",
        "params_string() is an alias for to_string()";
}

{
    note("--- set_file()");
    my $builder = Gnuplot::Builder::Dataset->new;
    identical $builder->set_file("foobar.dat"), $builder, "set_file() returns the dataset";
    is $builder->get_source(), q{'foobar.dat'}, "set_file() is an alias for setq_source()";
}

done_testing;
