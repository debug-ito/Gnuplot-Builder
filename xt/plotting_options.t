use strict;
use warnings;
use Test::More;
use Gnuplot::Builder::Script;
use Gnuplot::Builder::Process;

$Gnuplot::Buidler::Process::NO_STDERR = 0;
$Gnuplot::Buidler::Process::ASYNC = 0;

my $s = Gnuplot::Builder::Script->new->set_plot(
    no_stderr => 1
)->add(<<SCRIPT);
set print
print "STDERR!"
set print "-"
print "STDOUT!"
SCRIPT

is $s->run, "STDOUT!\n", "STDERR should be suppressed by no_stderr option";

done_testing;
