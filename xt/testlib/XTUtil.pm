package testlib::XTUtil;
use strict;
use warnings;
use Test::More;
use Exporter qw(import);

our @EXPORT_OK = qw(if_no_file);

sub if_no_file {
    my ($filename, $code) = @_;
  SKIP: {
        if(-e $filename) {
            skip "File $filename exists. Remove it first.", 1;
        }
        note("--- output $filename");
        $code->($filename);
    }
}


1;

