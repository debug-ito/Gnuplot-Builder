use strict;
use warnings;
use Test::More;
use Gnuplot::Builder::Script;
use Gnuplot::Builder::Process;

$Gnuplot::Buidler::Process::NO_STDERR = 0;
$Gnuplot::Buidler::Process::ASYNC = 0;

fail('test set_plot() actually takes effect on gnuplot processes. (just a simple use-case is enough)');

done_testing;
