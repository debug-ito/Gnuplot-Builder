package testlib::LensUtil;
use strict;
use warnings FATAL => "all";
use Test::More;
use Test::Identity;
use Exporter qw(import);
use Data::Focus qw(focus);

our @EXPORT_OK = qw(test_lens_options);

sub test_lens_options {
    my ($label, $new) = @_;
    note("--- test_lens_options: $label");
    {
        my $o = $new->();
        my $got_s = focus($o)->get("hoge");
        is $got_s, undef;
        my @got_l = focus($o)->get("hoge");
        is_deeply \@got_l, [undef], "one empty focal point at first";
    }
    {
        my $o = $new->();
        my $got_o = focus($o)->set(hoge => "foobar");
        identical $got_o, $o, "the lens should be destructive.";
        is scalar(focus($o)->get("hoge")), "foobar", "simple scalar: get";
        is_deeply [focus($o)->list("hoge")], ["foobar"], "simple scalar: list";
    }
    {
        my $o = $new->();
        identical focus($o)->set(hoge => ["foo", "bar"]), $o;
        is scalar(focus($o)->get("hoge")), "foo", "array-ref: get";
        is_deeply [focus($o)->list("hoge")], ["foo", "bar"], "array-ref: list";
        identical focus($o)->over(hoge => sub { uc(shift) }), $o;
        is_deeply [focus($o)->list("hoge")], ["FOO", "BAR"], "array-ref: list: after over";
    }
    {
        my $o = $new->();
        identical focus($o)->set(hoge => []), $o;
        is scalar(focus($o)->get("hoge")), undef, "empty array-ref: get";
        is_deeply [focus($o)->list("hoge")], [], "empty array-ref: list";

        ## Does the below code pass? I think it's already "no focal point", so we can set values there...
        identical focus($o)->set(hoge => "HOGE"), $o;
        is scalar(focus($o)->get("hoge")), "HOGE", "set after empty array-ref: get";
        is_deeply [focus($o)->list("hoge")], ["HOGE"], "set after empty array-ref: list";
    }
    {
        my $o = $new->();
        my $val = "val";
        identical focus($o)->set(hoge => sub { $val }), $o;
        is scalar(focus($o)->get("hoge")), "val", "code-ref: get";
        is_deeply [focus($o)->list("hoge")], ["val"], "code-ref: list";
        $val = "FOOBAR";
        is scalar(focus($o)->get("hoge")), "FOOBAR", "code-ref: get dynamic";
        is_deeply [focus($o)->list("hoge")], ["FOOBAR"], "code-ref: list dynamic";
    }
    {
        my $o = $new->();
        identical focus($o)->set(hoge => undef), $o;
        is scalar(focus($o)->get("hoge")), undef, "undef: get";
        is_deeply [focus($o)->list("hoge")], [undef], "undef: list";
    }
}

1;
