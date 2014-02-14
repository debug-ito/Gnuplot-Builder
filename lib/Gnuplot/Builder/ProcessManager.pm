package Gnuplot::Builder::ProcessManager;
use strict;
use warnings;
use Exporter qw(import);
use IPC::Open3 qw(open3);

our @COMMAND = qw(gnuplot --persist);
our $MAX_PROCESSES = 10;

our @EXPORT_OK = qw(spawn_gnuplot);

## return a writable filehandle into the new gnuplot process
sub spawn_gnuplot {
    my ($writer, $reader) = @_;
    my $pid = open3($writer, $reader, undef, @COMMAND);
    close $reader;
    return $writer;
}

1;

__END__

=pod

=head1 NAME

Gnuplot::Builder::ProcessManager - gnuplot process manager singleton

=head1 SYNOPSIS

    use Gnuplot::Builder::ProcessManager;
    
    @Gnuplot::Builder::ProcessManager::COMMAND = ("/path/to/gnuplot", "-p");

=head1 DESCRIPTION

L<Gnuplot::Builder::ProcessManager> manages gnuplot processes spawned
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

