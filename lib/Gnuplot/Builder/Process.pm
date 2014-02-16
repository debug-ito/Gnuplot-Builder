package Gnuplot::Builder::Process;
use strict;
use warnings;
use IPC::Open3 qw(open3);
use Carp;

our @COMMAND = qw(gnuplot --persist);
our $MAX_PROCESSES = 10;

my $END_SCRIPT_MARK = '@@@@@@_END_OF_GNUPLOT_BUILDER_@@@@@@';

sub new {
    my ($class) = @_;
    my $pid = open3(my $write_handle, my $read_handle, undef, @COMMAND);
    my $self = bless {
        pid => $pid,
        write_handle => $write_handle,
        read_handle => $read_handle,
        result => undef,
    }, $class;
    return $self;
}

sub writer {
    my ($self) = @_;
    croak "Input end is already closed" if not defined $self->{write_handle};
    my $write_handle = $self->{write_handle};
    return sub {
        print $write_handle (@_);
    };
}

sub close_input {
    my ($self) = @_;
    return if not defined $self->{write_handle};
    close $self->{write_handle};
    $self->{write_handle} = undef;
}

sub wait_to_finish {
    my ($self) = @_;
    my $write_handle = $self->{write_handle};
    foreach my $statement (qq{set print "-"}, qq{print '$END_SCRIPT_MARK'}, qq{exit}) {
        print $write_handle ($statement, "\n");
    }
    $self->close_input();
    
    my $result = "";
    my $read_handle = $self->{read_handle};
    while(defined(my $line = <$read_handle>)) {
        $result .= $line;

        ## Wait for $END_SCRIPT_MARK that we told the gnuplot to
        ## print. It is not enough to wait for EOF from $read_handle,
        ## because in some cases, $read_handle won't be closed even
        ## after the gnuplot process exits. For example, in Linux
        ## 'wxt' terminal, 'gnuplot --persist' process spawns its own
        ## child process to handle the wxt window. That child process
        ## inherits the file descriptors from the gnuplot process, and
        ## it won't close the output fd. So $read_handle won't be
        ## closed until we close the wxt window. This is not good
        ## especially we are in REPL mode.
        if($result =~ /^(.*)\Q$END_SCRIPT_MARK\E/s) {
            $result = $1;
            last;
        }
    }
    $self->{result} = $result;
    close $read_handle;
    waitpid $self->{pid}, 0;
}

sub result { $_[0]->{result} }



1;

__END__

=pod

=head1 NAME

Gnuplot::Builder::Process - gnuplot process manager

=head1 SYNOPSIS

    use Gnuplot::Builder::Process;
    
    @Gnuplot::Builder::Process::COMMAND = ("/path/to/gnuplot", "-p");

=head1 DESCRIPTION

L<Gnuplot::Builder::Process> class manages gnuplot processes spawned
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

