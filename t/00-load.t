use 5.006;
use strict;
use warnings;
use Test::More;
 
plan tests => 1;
 
BEGIN {
    use_ok( 'Gnuplot::Builder' ) || print "Bail out!\n";
}
 
diag( "Testing Gnuplot::Builder $Gnuplot::Builder::VERSION, Perl $], $^X" );
