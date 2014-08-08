package testlib::XTUtil;
use strict;
use warnings;
use Test::More;
use Exporter qw(import);
use Gnuplot::Builder::Process;

our @EXPORT_OK = qw(if_no_file check_process_finish);

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

sub check_process_finish {
    note("wait for all managed sub-processes to finish");
    Gnuplot::Builder::Process::FOR_TEST_wait_all();
    my $ps = `ps aux | grep gnuplot | grep -v 'grep gnuplot'`;
    my $status = ($? >> 8);
    if($!) {
        note("ps returned error: $!");
    }else {
        cmp_ok $status, "!=", 0, "grep should fail to find the match. There should not be any gnuplot process" or do {
            note("result of ps...");
            note($ps);
        };
    }
}

1;

