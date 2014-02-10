use strict;
use warnings;
use Test::More;
use Test::Identity;
use Gnuplot::Builder::Script;

{
    note("--- get non-existent");
    my $builder = Gnuplot::Builder::Script->new;
    is_deeply [$builder->get_option("hoge")], [], "non-existent value returns an empty list";
}

{
    note("--- get plain data");
    foreach my $case (
        {label => 'undef', set => undef, exp => [undef]},
        {label => "string", set => "foo", exp => ["foo"]},
        {label => "empty array", set => [], exp => []},
        {label => "array", set => ["foo", "bar"], exp => ["foo", "bar"]},
    ) {
        my $builder = Gnuplot::Builder::Script->new;
        $builder->set(hoge => $case->{set});
        is_deeply [$builder->get_option("hoge")], $case->{exp}, "$case->{label}: get_option() OK";
    }
}

{
    note("--- get lazy values from code-ref");
    foreach my $case (
        {label => "code-ref -> string", set => sub { "foo" }, exp => ["foo"]},
        {label => "code-ref -> empty", set => sub { () }, exp => []},
        {label => "code-ref -> list", set => sub { ("foo", "bar") }, exp => ["foo", "bar"]},
        {label => "code-ref -> undef", set => sub { undef }, exp => [undef]},
    ) {
        my $builder = Gnuplot::Builder::Script->new;
        my $called = 0;
        $builder->set(hoge => sub {
            $called++;
            return $case->{set}->();
        });
        is_deeply [$builder->get_option("hoge")], $case->{exp}, "$case->{label}: get_option() for code-ref OK";
        is $called, 1, "$case->{label}: value code-ref is called once";
    }
}

{
    note("--- get values set by setq()");
    foreach my $case (
        {label => "string", set => "hoge", exp => [q{'hoge'}]},
        {label => "array", set => ["foo", "bar"], exp => [q{'foo'}, q{'bar'}]},
        {label => "code-ref", set => sub { ("foo", "bar" ) }, exp => [q{'foo'}, q{'bar'}]}
    ) {
        my $builder = Gnuplot::Builder::Script->new;
        $builder->setq(hoge => $case->{set});
        is_deeply [$builder->get_option("hoge")], $case->{exp}, "$case->{label}: get_option() with setq() OK";
    }
}

done_testing;
