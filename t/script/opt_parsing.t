use strict;
use warnings;
use Test::More;
use Gnuplot::Builder::Script;

{
    note("--- example");
    my $builder = Gnuplot::Builder::Script->new;
    $builder->set(<<'EOT');
xrange = [-5:10]
output = "foo.png"
grid
-key

## terminal = png size 100,200
terminal = pngcairo size 400,800

tics = mirror in \
       rotate autojustify

arrow = 1 from 0,10 to 10,0
arrow = 2 from 5,5  to 10,10
EOT
    is $builder->to_string, <<EXP;
set xrange [-5:10]
set output "foo.png"
set grid
unset key
set terminal pngcairo size 400,800
set tics mirror in        rotate autojustify
set arrow 1 from 0,10 to 10,0
set arrow 2 from 5,5  to 10,10
EXP
}

{
    note("--- trailing backslash should take effect before commenting out.");
    my $builder = Gnuplot::Builder::Script->new;
    $builder->set(<<'EOT');
## due to trailing backslash, the next line is also commented out \
title = "foobar"
EOT
    is $builder->to_string, "";
}

done_testing;

