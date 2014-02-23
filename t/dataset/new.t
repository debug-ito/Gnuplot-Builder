use strict;
use warnings;
use Test::More;
use Gnuplot::Builder::Dataset;

{
    note("--- new()");
    my $dataset = Gnuplot::Builder::Dataset->new();
    is $dataset->to_string, "", "empty";
    
    $dataset = Gnuplot::Builder::Dataset->new('f(x)', with => "lp", lw => 3);
    is $dataset->to_string, "f(x) with lp lw 3", "source and opts OK";
    is $dataset->get_option("with"), "lp", "option 'with' OK";
}

{
    note("--- new_file()");
    my $dataset = Gnuplot::Builder::Dataset->new_file();
    is $dataset->to_string, "", "empty";
    
    $dataset = Gnuplot::Builder::Dataset->new_file('hoge.dat', u => "3:4", every => "::1");
    is $dataset->to_string, q{'hoge.dat' u 3:4 every ::1}, "file and opts OK";
    is $dataset->get_option("every"), "::1", "option 'every' OK";
}

TODO: {
    local $TODO = "not implemented yet";
    note("--- new_data()");
    fail("do the test");
}

done_testing;
