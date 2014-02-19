use strict;
use warnings;
use Test::More;

fail('Exception during plotting. Throwers are lazy-eval values for script and dataset and inline data provider. It should terminate the gnuplot process.');

done_testing;

