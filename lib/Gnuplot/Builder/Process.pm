package Gnuplot::Builder::Process;
use strict;
use warnings;
use IPC::Open3 qw(open3);
use Carp;
use Gnuplot::Builder::PartiallyKeyedList;
use POSIX qw(:sys_wait_h);
use Guard ();
use File::Spec;

our @COMMAND = qw(gnuplot --persist);
our $MAX_PROCESSES = 10;

my $END_SCRIPT_MARK = '@@@@@@_END_OF_GNUPLOT_BUILDER_@@@@@@';
my $processes = Gnuplot::Builder::PartiallyKeyedList->new;

sub _clear_zombies {
    my @proc_objs = ();
    $processes->each(sub { push(@proc_objs, $_[1]) }); ## collect procs first because _waitpid() manipulates $processes...
    $_->_waitpid(0) foreach @proc_objs;
}

{
    my $null_handle;
    sub _null_handle {
        return $null_handle if defined $null_handle;
        my $devnull = File::Spec->devnull();
        open $null_handle, ">", $devnull or confess("Cannot open $devnull: $!");
        return $null_handle;
    }
}

## PUBLIC ONLY IN TESTS: number of processes it keeps now
sub FOR_TEST_process_num { $processes->size }


## create a new gnuplot process. it blocks if the number of processes
## has reached $MAX_PROCESSES.
##
## Fields in %args are:
##
## capture (BOOL optional, default: false): If true, it keeps the
## STDOUT and STDERR of the process so that it can read them
## afterward. Otherwise, it just discards the output.
sub new {
    my ($class, %args) = @_;
    _clear_zombies();
    while($MAX_PROCESSES > 0 && $processes->size() >= $MAX_PROCESSES) {
        ## wait for the first process to finish. it's not the smartest
        ## way, but is it possible to wait for specific set of
        ## processes?
        my ($pid, $proc) = $processes->get_at(0);
        $proc->_waitpid(1);
    }
    my $capture = $args{capture};
    my ($write_handle, $read_handle, $pid);
    
    ## open3() does not seem to work well with lexical filehandles, so we use fileno()
    $pid = open3($write_handle,
                 $capture ? $read_handle : '>&'.fileno(_null_handle()),
                 undef, @COMMAND);
    my $self = bless {
        pid => $pid,
        write_handle => $write_handle,
        read_handle => $read_handle,
        result => undef,
    }, $class;
    $processes->set($pid, $self);
    return $self;
}

## Return the writer code-ref for this process.
sub writer {
    my ($self) = @_;
    croak "Input end is already closed" if not defined $self->{write_handle};
    my $write_handle = $self->{write_handle};
    return sub {
        print $write_handle (@_);
    };
    ## If we are serious about avoiding dead-lock, we must use
    ## select() to check writability first and to read from the
    ## read_handle. But I guess the dead-lock happens only if the
    ## user inputs too much data and the gnuplot outputs too much
    ## data to STDOUT/STDERR. That's rare.
}

## Close the input channel. You can call this method multiple times.
sub close_input {
    my ($self) = @_;
    return if not defined $self->{write_handle};
    my $write_handle = $self->{write_handle};
    print $write_handle "\n";
    foreach my $statement (qq{set print "-"}, qq{print '$END_SCRIPT_MARK'}, qq{exit}) {
        print $write_handle ($statement, "\n");
    }
    close $self->{write_handle};
    $self->{write_handle} = undef;
}

sub _waitpid {
    my ($self, $blocking) = @_;
    my $result = waitpid($self->{pid}, $blocking ? 0 : WNOHANG);
    if($result == $self->{pid}) {
        $processes->delete($self->{pid});
    }
}

## Blocks until the process finishes. It automatically close the input
## channel if necessary.
sub wait_to_finish {
    my ($self) = @_;
    $self->close_input();
    
    my $read_handle = $self->{read_handle};
    if(defined $read_handle) {
        my $result = "";
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
            my $end_position = index($result, $END_SCRIPT_MARK);
            if($end_position != -1) {
                $result = substr($result, 0, $end_position);
                last;
            }
        }
        $self->{result} = $result;
        close $read_handle;
    }
    $self->_waitpid(1);
}

## Get the result of the finished process. Valid only after calling
## wait_to_finish().
sub result { $_[0]->{result} }

## Return a Guard object. When the Guard is DESTROYed, the gnuplot
## process is forced to terminate. Call cancel() method on the guard
## to cancel the termination.
sub terminator_guard {
    my ($self) = @_;
    return Guard::guard {
        kill 'TERM', $self->{pid};
    };
}


#### #### #### #### #### #### #### #### #### #### #### #### #### 

package Gnuplot::Builder::Process::MockTool;
use strict;
use warnings;

## tools for a process who mocks gnuplot, i.e., the process who
## communicates with Gnuplot::Builder::Process.


## Receive data from Gnuplot::Builder::Process and execute the $code
## with the received data.
sub receive_from_builder {
    my ($input_handle, $output_handle, $code) = @_;
    while(defined(my $line = <$input_handle>)) {
        $code->($line);

        ## Windows does not signal EOF on $input_handle so we must
        ## detect the end of script by ourselves.
        if(index($line, $END_SCRIPT_MARK) != -1) {
            print $output_handle "$END_SCRIPT_MARK\n";
            $code->("exit\n");
            last;
        }
    }
}


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

