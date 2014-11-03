use strict;
use warnings FATAL => "all";
use Test::More;
use Test::Fatal;
use Scalar::Util qw(refaddr);
use Gnuplot::Builder::JoinDict;

sub is_different {
    my ($obj1, $obj2, $msg) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    isnt refaddr($obj1), refaddr($obj2), $msg;
}

sub str_ok {
    my ($dict, $exp, $msg) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    $msg = "" if not defined $msg;
    is $dict->to_string, $exp, "to_string(): $msg";
    is "$dict", $exp, qq{"": $msg};
}

{
    note('--- default');
    str_ok(Gnuplot::Builder::JoinDict->new(), "", "no arg OK");
    str_ok(Gnuplot::Builder::JoinDict->new(separator => "###"), "", "no content OK");
    str_ok(Gnuplot::Builder::JoinDict->new(content => [x => 1, y => 2, z => 3]), "123", "no separator OK");
}

{
    note('--- content variation');
    my $SEP = ":";
    foreach my $case (
        {label => "empty", content => [], exp => ""},
        {label => "single", content => [x => 1], exp => "1"},
        {label => "two", content => [x => 1, y => 2], exp => "1:2"},
        {label => "with undefs", content => [a => undef, b => 2, c => undef, d => 4, e => undef, f => undef],
         exp => "2:4"},
        {label => "with empty strings", content => [a => '', b => 2, c => '', d => 4, e => '', f => ''],
         exp => ":2::4::"},
        {label => "duplicate keys", content => [a => 1, a => 2, a => 3], exp => '3'},
    ) {
        str_ok(Gnuplot::Builder::JoinDict->new(separator => $SEP, content => $case->{content}), $case->{exp}, "$case->{label} OK");
    }
}

{
    my $orig = Gnuplot::Builder::JoinDict->new(
        separator => ":",
        content => [a => 1, b => 2, _b => undef, c => 3, d => 4]
    );
    
    note('--- set()');
    foreach my $case (
        {label => "single override", input => [c => 30], exp => '1:2:30:4'},
        {label => "single addition", input => [e => 5], exp => '1:2:3:4:5'},
        {label => "multi mixed", input => [f => 99, d => 40, b => undef], exp => '1:3:40:99'},
        {label => "duplicate keys", input => [g => 100, b => 22, g => 200, b => 222, g => 300], exp => '1:222:3:4:300'},
        {label => "revive undef", input => [_b => 23], exp => '1:2:23:3:4'},
    ) {
        my $new = $orig->set(@{$case->{input}});
        is_different $new, $orig, "$case->{label}: set() returns a new object";
        str_ok $orig, "1:2:3:4", "$case->{label}: set() keeps the original intact";
        str_ok $new, $case->{exp}, "$case->{exp}: set() result OK";
    }

    note('--- delete()');
    foreach my $case (
        {label => "single", input => ["c"], exp => '1:2:4'},
        {label => "single no exist", input => ["f"], exp => '1:2:3:4'},
        {label => "multi mixed", input => [qw(f e b)], exp => '1:3:4'},
        {label => "delete undef value", input => ["_b"], exp => '1:2:3:4'}
    ) {
        my $new = $orig->delete(@{$case->{input}});
        is_different $new, $orig, "$case->{label}: delete() returns a new object";
        str_ok $orig, "1:2:3:4", "$case->{label}: delete() keeps the original intact";
        str_ok $new, $case->{exp}, "$case->{label}: delete() result OK";
    }

    note('--- delete() -> set()');
    str_ok $orig->delete("c")->set(c => 3), "1:2:4:3", "delete() -> set() rearrange the order";

    note('--- clone()');
    my $clone = $orig->clone;
    is_different $clone, $orig, "clone is a different object";
    str_ok $clone, "$orig", "clone string OK";
    
    note('--- get()');
    foreach my $case (
        {in => "a", exp => 1}, {in => "b", exp => 2},
        {in => "_b", exp => undef}, {in => "c", exp => 3},
        {in => "d", exp => 4}, {in => "this does not exist", exp => undef}
    ) {
        is $orig->get($case->{in}), $case->{exp}, "get: $case->{in}: OK";
        is $clone->get($case->{in}), $case->{exp}, "get: $case->{in}: clone OK";
    }
}

{
    note('--- illegal input');
    foreach my $case (
        {label => "odd number content", input => [x => 1, 3], exp => qr/odd number/i},
        {label => "undef key", input => [undef, 10], exp => qr/undefined key/i},
    ) {
        like exception { Gnuplot::Builder::JoinDict->new(content => $case->{input}) }, $case->{exp}, "new(): $case->{label}";
        my $d = Gnuplot::Builder::JoinDict->new;
        like exception { $d->set(@{$case->{input}}) }, $case->{exp}, "set(): $case->{label}";
    }
}

done_testing;
