package Gnuplot::Builder::Process;
use strict;
use warnings;
use IPC::Open3 qw(open3);

our @COMMAND = qw(gnuplot --persist);
our $MAX_PROCESSES = 10;

sub new {
    my ($class) = @_;
    my $result = "";
    open(my $result_handle, ">", \$result) or confess("Cannot open in-memory buffer.");
    my $pid = open3(my $writer, $result_handle, undef, @COMMAND);
    my $self = bless {
        pid => $pid,
        write_handle => $writer,
        result_handle => $result_handle,
        result_ref => \$result,
    }, $class;
    return $self;
}

sub writer {
    my ($self) = @_;
    my $write_handle = $self->{write_handle};
    return sub {
        print $write_handle (@_);
    };
}

sub wait_to_finish {
    my ($self) = @_;
    close $self->{write_handle};
    waitpid $self->{pid}, 0;
}

sub result { ${$_[0]->{result_ref}} }



1;

__END__

=pod

=head1 NAME

Gnuplot::Builder::Process - gnuplot process manager singleton

=head1 SYNOPSIS

    use Gnuplot::Builder::Process;
    
    @Gnuplot::Builder::Process::COMMAND = ("/path/to/gnuplot", "-p");

=head1 DESCRIPTION

L<Gnuplot::Builder::Process> manages gnuplot processes spawned
by all L<Gnuplot::Builder::Script> objects.

You can configure its package variables to change its behavior.

=head1 PACKAGE VARIABLES

=head2 @COMMAND

The command and arguments to run a gnuplot process.

By default, it's C<("gnuplot", "--persist")>.

=head2 $MAX_PROCESSES

Maximum number of gnuplot processes that can run in parallel.
If C<$MAX_PROCESSES> <= 0, the number of processes is unlimited.

By default, it's C<10>.

=head1 AUTHOR

Toshio Ito, C<< <toshioito at cpan.org> >>


=cut

