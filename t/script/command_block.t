use strict;
use warnings;
use Test::More;

note("--- tests about command blocks of multiplot() and run()");

fail("what to return when plotting methods (like plot()) is called within multiplot block. Empty string?");
fail("what if plot_with(async => 1) within multiplot block? or should I test the case with run() method?");
fail("plotting methods inside multiplot() / run()");
fail("nested run and multiplot blocks");
fail("specifying explicit writer in multiplot() and run() blocks.");
fail("exception from nested blocks");

fail("xt: make sure only one process is run in nested plots");

done_testing;
