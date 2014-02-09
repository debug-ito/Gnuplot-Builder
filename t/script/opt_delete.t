use strict;
use warnings;
use Test::More;
use Test::Identity;
use Gnuplot::Builder::Script;

{
    my $builder = Gnuplot::Builder::Script->new;
    identical $builder->delete_option("hoge"), $builder, "delete() should return the builder";

    $builder->set(
        a => "A",
        b => "B",
        c => "C"
    );
    $builder->delete_option("b");
    is $buidler->to_string(), <<EXP;
set a A
set c C
EXP
    is_deeply [$builder->get_option("b")], [];

    $builder->set(b => "B2");
    is $builder->to_string(), <<EXP;
set a A
set c C
set b B2
EXP
}

done_testing;
