use strict;
use warnings;
use Test::More;
use Test::Identity;
use Gnuplot::Builder::Script;

{
    my $builder = Gnuplot::Builder::Script->new;
    identical $builder->define(a => 10), $builder, "define() should return the object";

    my $called = 0;
    $builder->define(b => [20, 30], c => undef, "f(x)" => sub {
        my ($inner_builder, $key) = @_;
        $called++;
        identical $inner_builder, $builder, "first arg for code-ref OK";
        is $key, "f(x)", "second arg for code-ref OK";
        ok wantarray, "list context ok";
        return "sin(x)";
    });
    is $called, 0, "not yet called";
    is $builder->to_string, <<EXP, "script OK";
a = 10
b = 20
b = 30
undefine c
f(x) = sin(x)
EXP
    is $called, 1, "called";
    $called = 0;

    is_deeply [$builder->get_definition("a")], [10], "get single definition";
    is_deeply [$builder->get_definition("b")], [20, 30], "get multiple occurrences";
    is_deeply [$builder->get_definition("c")], [undef], "get undef";
    is_deeply [$builder->get_definition("f(x)")], ["sin(x)"], "get code-ref";
    is_deeply [$builder->get_definition("d")], [], "get non-existent";
    is $called, 1, "called once";

    identical $builder->delete_definition("b"), $builder, "delete_definition() should return the object";
    is_deeply [$builder->get_definition("b")], [], "b no longer exists";
    is $builder->to_string, <<EXP, "b is deleted";
a = 10
undefine c
f(x) = sin(x)
EXP
    $builder->delete_definition("a", "f(x)");
    is $builder->to_string, <<EXP, "delete multiple definitions";
undefine c
EXP
}

{
    my $builder = Gnuplot::Builder::Script->new;
    identical $builder->set_definition(<<EOT), $builder, "set_definition() should return the object";
a = 10
b

c = ""
f(x, y) = sin(x) * cos(y)

-d
EOT
    is $builder->to_string, <<EXP, "set_definition() with setting script OK";
a = 10
b =
c = ""
f(x, y) = sin(x) * cos(y)
undefine d
EXP
}

{
    my $builder = Gnuplot::Builder::Script->new;
    identical $builder->undefine(qw(a b c)), $builder, "undefine() should return the object";
    is $builder->to_string, <<EXP, "undefine() OK";
undefine a
undefine b
undefine c
EXP
}

done_testing;
