use strict;
use warnings;
use Test::More;
use Gnuplot::Builder::Script;
use Gnuplot::Builder::Process;

{
    my $script = Gnuplot::Builder::Script->new(
        samples => 10000,
        term => "postscript",
        xrange => "[-100:100]",
    );
    $script->plot_with(dataset => "sin(x)", async => 1);
    sleep 1;
    $script->set(samples => 100);
    $script->plot("sin(x)"); ## try to reap the first process
    is(Gnuplot::Builder::Process->FOR_TEST_process_num, 0, "all processes finished.");
}


done_testing;


