use strict;
use warnings;
use Test::More;
use Test::Identity;
use Gnuplot::Builder::Script;

foreach my $case (
    {label => "normal", input => 'hoge.png', exp => qq{set output 'hoge.png'\n}},
    {label => "including apos", input => "hoge's values", exp => qq{set output 'hoge''s values'\n}},
    {label => "undef", input => undef, exp => qq{unset output\n}},
    {label => "empty array-ref", input => [], exp => qq{}},
    {label => "array-ref", input => ["foo", "bar"], exp => qq{set output 'foo'\nset output 'bar'\n}},
    {label => "code-ref -> string", input => sub { "hoge" }, exp => qq{set output 'hoge'\n}},
    {label => "code-ref -> list", input => sub { ("foo", "bar") }, exp => qq{set output 'foo'\nset output 'bar'\n}},
    
) {
    my $builder = Gnuplot::Builder::Script->new;
    identical $builder->setq(output => $case->{give}), $builder, "$case->{label}: setq() returns the builder";
    is $builder->to_string, $case->{exp}, "$case->{label}: quoted OK";
}


done_testing;
