use 5.006;
use strict;
use warnings;
use Test::More;
 
use Test::ConsistentVersion;

unless($ENV{RELEASE_TESTING}) {
    plan(skip_all => "Set RELEASE_TESTING environment variable to test VERSION consistency");
}

Test::ConsistentVersion::check_consistent_versions(
    no_pod => 1, no_readme => 1
);
done_testing;
