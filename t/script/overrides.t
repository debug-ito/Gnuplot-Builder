use strict;
use warnings;
use Test::More;
use Test::MockObject::Extends;
use Gnuplot::Builder::Script;

my $builder = Gnuplot::Builder::Script->new(
    key => "columnheader"
);
my $orig = $builder->can('to_string');
my $called = 0;
Test::MockObject::Extends->new($builder);
$builder->mock('to_string', sub {
    $called++;
    goto $orig;
});

is "$builder", "set key columnheader\n", "stringification ok";
is $called, 1, "stringification should be overridden by to_string()";

done_testing;
