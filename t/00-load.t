use 5.006;
use strict;
use warnings;
use Test::More;
 
BEGIN {
    foreach my $module ("", "::Script", "::Dataset") {
        use_ok('Gnuplot::Builder' . $module);
    }
}
 
diag( "Testing Gnuplot::Builder $Gnuplot::Builder::VERSION, Perl $], $^X" );
done_testing;
