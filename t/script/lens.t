use strict;
use warnings FATAL => "all";
use Test::More;
use Gnuplot::Builder::Script;
use Test::Requires { "Data::Focus" => "0.03" };
use lib "t";
use testlib::LensUtil qw(test_lens_options);

test_lens_options("Script", sub { Gnuplot::Builder::Script->new });

done_testing;
