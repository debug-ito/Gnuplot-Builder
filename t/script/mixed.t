use strict;
use warnings;
use Test::More;
use Gnuplot::Builder::Script;

fail("mixed settings of add, set and define");

{
    note("--- set and define example");
    my $builder = Gnuplot::Builder::Script->new;
    $builder->set(
        xtics => 10,
        key   => undef
    );
    $builder->define(
        a      => 100,
        'f(x)' => 'sin(a * x)',
        b      => undef
    );
    is $builder->to_string(), <<'EXP', "mixed set() and define() ok";
set xtics 10
unset key
a = 100
f(x) = sin(a * x)
undefine b
EXP
}

done_testing;
