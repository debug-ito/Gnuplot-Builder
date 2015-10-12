use strict;
use warnings FATAL => "all";
use Test::More;
use Gnuplot::Builder::Script;
use Gnuplot::Builder::Process;

$Gnuplot::Buidler::Process::NO_STDERR = 0;

fail('basic set-get-delete operation');
fail('passing code-ref, get it as-is');
fail('passing array-ref, get it as-is');

fail('effect on short-hands (plot() etc.)');

fail('override by given arguments');

fail('exception on unknown argument');

fail('inheritance set-get-delete');

done_testing;
