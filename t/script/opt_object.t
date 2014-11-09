use strict;
use warnings FATAL => "all";
use Test::More;
use Test::Identity;
use Gnuplot::Builder::Script;
use Gnuplot::Builder::JoinDict;

my $val = Gnuplot::Builder::JoinDict->new(
    separator => ",", content => [width => 400, height => 300]
);
foreach my $case (
    {label => "single", method => "set_option",
     val => $val, exp => qq{set term 400,300\n}, extract => sub { $_[0] }},
    {label => "in array", method => "set_option",
     val => ["foo", $val], exp => qq{set term foo\nset term 400,300\n}, extract => sub { $_[1] }},
    {label => "from code", method => "set_option",
     val => sub { ("foo", $val) }, exp => qq{set term foo\nset term 400,300\n}, extract => sub { $_[1] }},

    {label => "single", method => "setq_option",
     val => $val, exp => qq{set term '400,300'\n}, extract => sub { $_[0] }},
    {label => "in array", method => "setq_option",
     val => ["foo", $val], exp => qq{set term 'foo'\nset term '400,300'\n}, extract => sub { $_[1] }},
    {label => "from code", method => "setq_option",
     val => sub { ("foo", $val) }, exp => qq{set term 'foo'\nset term '400,300'\n}, extract => sub { $_[1] }},
) {
    my $script = Gnuplot::Builder::Script->new;
    my $method = $case->{method};
    $script->$method(term => $case->{val});
    is $script->to_string, $case->{exp}, "$case->{label}: $case->{method}: to_string() OK";

    my $got_object = $case->{extract}->($script->get_option("term"));
    if($case->{method} eq "set_option") {
        identical $got_object, $val, "$case->{label}: $case->{method}: get_option() returns the object";
    }else {
        ok !ref($got_object), "$case->{label}: $case->{method}: get_option() returns a stringified and quoted object";
    }
}


done_testing;
