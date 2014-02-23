use strict;
use warnings;
use Test::More;
use Test::Identity;
use Gnuplot::Builder::Dataset;

{
    my $dataset = Gnuplot::Builder::Dataset->new;
    is_deeply [$dataset->get_option("foo")], [], "get non-existent option";
    identical $dataset->delete_option("foo"), $dataset, "delete non-existent option is OK";
    
    $dataset->set_option(foo => "bar");
    is_deeply [$dataset->get_option("foo")], ["bar"], "set foo";
    identical $dataset->delete_option("foo"), $dataset, "delete foo";
    is_deeply [$dataset->get_option("foo")], [], "foo is deleted";
}

done_testing;

