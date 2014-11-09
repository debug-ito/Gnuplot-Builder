use strict;
use warnings FATAL => "all";
use Test::More;
use Test::Identity;
use Test::Fatal;
use lib "t";
use testlib::RefUtil qw(is_different);
use Gnuplot::Builder::JoinDict;

{
    note("--- example");
    my $dict = Gnuplot::Builder::JoinDict->new(
        separator => " & ", content => [x => 10, y => 20],
        filter => sub {
            my ($dict, $keys, $values) = @_;
            return [map { "$keys->[$_]=$values->[$_]" } 0 .. $#$keys]
        }
    );
    is "$dict", "x=10 & y=20", "example OK";
}

{
    note("--- filter sub environment");
    my $called = 0;
    my $dict; $dict = Gnuplot::Builder::JoinDict->new(
        separator => ":",
        filter => sub {
            my ($inner_dict, $keys, $values) = @_;
            $called++;
            ok((!wantarray && defined(wantarray)), "filter is in scalar context");
            identical $inner_dict, $dict, "inner_dict is the containing object";
            is_deeply $keys, [], "keys ok";
            is_deeply $values, [], "values ok";
            return [1,2,3];
        }
    );
    is $called, 0, "not called yet";
    is "$dict", "1:2:3", "stringification ok";
    is $called, 1, "called";
}

{
    note("--- filter modifying keys and values");
    my $called = 0;
    my $dict = Gnuplot::Builder::JoinDict->new(
        separator => ":", content => [x => 10, y => 20],
        filter => sub {
            my ($dict, $keys, $values) = @_;
            $called++;
            is_deeply $keys, [qw(x y)], "keys ok";
            is_deeply $values, [10, 20], "values ok";
            my $ret = [map { "$keys->[$_]=$values->[$_]" } 0 .. $#$keys];
            @{$_[1]} = ();
            @{$_[2]} = ();
            return $ret;
        }
    );
    is $called, 0, "not called yet";
    is "$dict", "x=10:y=20", "stringification ok";
    is $called, 1, "called once";
    is $dict->get("x"), 10, "get(x) ok";
    is $dict->get("y"), 20, "get(y) ok";
    is "$dict", "x=10:y=20", "stringification is ok again";
    is $called, 2, "called twice";
}

foreach my $case (
    {label => "empty", ret => [], exp => ""},
    {label => "include undefs", ret => [undef, 10, 20, undef, 30, undef], exp => "10:20:30"},
) {
    my $dict = Gnuplot::Builder::JoinDict->new(
        separator => ":", content => [foo => "bar", buzz => "quux"],
        filter => sub { $case->{ret} }
    );
    is "$dict", $case->{exp}, "$case->{label}: stringification ok";
}

{
    note("--- filter inheritance via setters and clone()");
    my $parent = Gnuplot::Builder::JoinDict->new(
        separator => ":", content => [x => 10, y => 20],
        filter => sub { [map { $_ * 2 } @{$_[2]}] },
    );
    is "$parent", "20:40", "parent ok";
    my $clone = $parent->clone();
    is_different $clone, $parent, "clone is not parent";
    is "$clone", "20:40", "clone() inherit filter ok";

    my $set = $parent->set(y => 200, z => 300);
    is "$set", "20:400:600", "set() inherit filter ok";

    my $del = $parent->delete("x");
    is "$del", "40", "delete() inherit filter ok";
}

{
    note("--- filter returning non array-ref");
    my $dict = Gnuplot::Builder::JoinDict->new(filter => sub { "a" });
    like exception { "$dict" }, qr{must return an array-ref}i, "exception ok";
}

{
    note("--- filter throwing exception");
    my $dict = Gnuplot::Builder::JoinDict->new(filter => sub { die "BOOM!" });
    like exception { "$dict" }, qr{BOOM!}, "exception ok";
}

done_testing;
