package Gnuplot::Builder::Script;
use strict;
use warnings;
use Gnuplot::Builder::PrototypedData;
use Gnuplot::Builder::Util qw(quote_gnuplot_str);
use Gnuplot::Builder::Process;
use Gnuplot::Builder::Version; our $VERSION = $Gnuplot::Builder::Version::VERSION;
use Scalar::Util qw(weaken);
use Carp;
use overload '""' => "to_string";

sub new {
    my ($class, @set_args) = @_;
    my $self = bless {
        pdata => undef,
        parent => undef,
    };
    $self->_init_pdata();
    if(@set_args) {
        $self->set(@set_args);
    }
    return $self;
}

sub _init_pdata {
    my ($self) = @_;
    weaken $self;
    $self->{pdata} = Gnuplot::Builder::PrototypedData->new(
        entry_evaluator => sub {
            my ($key, $value_code) = @_;
            if(defined($key)) {
                return $value_code->($self, substr($key, 1));
            }else {
                return $value_code->($self);
            }
        }
    );
}

sub add {
    my ($self, @sentences) = @_;
    foreach my $sentence (@sentences) {
        $self->{pdata}->add_entry($sentence);
    }
    return $self;
}

sub _set_entry {
    my ($self, $prefix, $quote, @pairs) = @_;
    $self->{pdata}->set_entry(
        entries => \@pairs,
        key_prefix => $prefix,
        quote => $quote,
    );
    return $self;
}

sub set {
    my ($self, @pairs) = @_;
    return $self->_set_entry("o", 0, @pairs);
}

*set_option = *set;

sub setq {
    my ($self, @pairs) = @_;
    return $self->_set_entry("o", 1, @pairs);
}

*setq_option = *setq;

sub unset {
    my ($self, @names) = @_;
    return $self->set(map { $_ => undef } @names);
}

sub _get_entry {
    my ($self, $prefix, $name) = @_;
    croak "name cannot be undef" if not defined $name;
    return $self->{pdata}->get_resolved_entry("$prefix$name");
}

sub get_option {
    my ($self, $name) = @_;
    return $self->_get_entry("o", $name);
}

sub _delete_entry {
    my ($self, $prefix, @names) = @_;
    foreach my $name (@names) {
        croak "name cannot be undef" if not defined $name;
        $self->{pdata}->delete_entry("$prefix$name");
    }
    return $self;
}

sub delete_option {
    my ($self, @names) = @_;
    return $self->_delete_entry("o", @names);
}

sub _create_statement {
    my ($raw_key, $value) = @_;
    return $value if !defined $raw_key;
    my ($prefix, $name) = (substr($raw_key, 0, 1), substr($raw_key, 1));
    my @words = ();
    if($prefix eq "o") {
        @words = defined($value) ? ("set", $name, $value) : ("unset", $name);
    }elsif($prefix eq "d") {
        @words = defined($value) ? ($name, "=", $value) : ("undefine", $name);
    }else {
        confess "Unknown key prefix: $prefix";
    }
    return join(" ", grep { $_ ne "" } @words);
}

sub to_string {
    my ($self) = @_;
    my $result = "";
    $self->{pdata}->each_resolved_entry(sub {
        my ($raw_key, $values) = @_;
        foreach my $value (@$values) {
            my $statement = _create_statement($raw_key, $value);
            $result .= $statement;
            $result .= "\n" if $statement !~ /\n$/;
        }
    });
    return $result;
}

sub define {
    my ($self, @pairs) = @_;
    return $self->_set_entry("d", 0, @pairs);
}

*set_definition = *define;

sub undefine {
    my ($self, @names) = @_;
    return $self->define(map { $_ => undef } @names);
}

sub get_definition {
    my ($self, $name) = @_;
    return $self->_get_entry("d", $name);
}

sub delete_definition {
    my ($self, @names) = @_;
    return $self->_delete_entry("d", @names);
}

sub set_parent {
    my ($self, $parent) = @_;
    if(!defined($parent)) {
        $self->{parent} = undef;
        $self->{pdata}->set_parent(undef);
        return $self;
    }
    if(!ref($parent) || !$parent->isa("Gnuplot::Builder::Script")) {
        croak "parent must be a Gnuplot::Builder::Script"
    }
    $self->{parent} = $parent;
    $self->{pdata}->set_parent($parent->{pdata});
    return $self;
}

sub parent { return $_[0]->{parent} }

sub new_child {
    my ($self) = @_;
    return Gnuplot::Builder::Script->new->set_parent($self);
}

sub _collect_dataset_params {
    my ($dataset_arrayref) = @_;
    my @params_str = ();
    my @dataset_objects = ();
    foreach my $dataset (@$dataset_arrayref) {
        my $ref = ref($dataset);
        if(!$ref) {
            push(@params_str, $dataset);
        }else {
            if(!$dataset->can("params_string") || !$dataset->can("write_data_to")) {
                croak "You cannot use $ref object as a dataset.";
            }
            my ($param_str) = $dataset->params_string();
            push(@params_str, $param_str);
            push(@dataset_objects, $dataset);
        }
    }
    return (\@params_str, \@dataset_objects);
}

sub _write_inline_data {
    my ($writer, $dataset_objects_arrayref) = @_;
    my $ended_with_newline = 0;
    my $data_written = 0;
    my $wrapped_writer = sub {
        my @nonempty_data = grep { defined($_) && $_ ne "" } @_;
        return if !@nonempty_data;
        $data_written = 1;
        $ended_with_newline = ($nonempty_data[-1] =~ /\n$/);
        $writer->(join("", @nonempty_data));
    };
    foreach my $dataset (@$dataset_objects_arrayref) {
        $data_written = $ended_with_newline = 0;
        $dataset->write_data_to($wrapped_writer);
        next if !$data_written;
        $writer->("\n") if !$ended_with_newline;
        $writer->("e\n");
    }
}

sub _draw_with {
    my ($self, %args) = @_;
    my $plot_command = $args{command};
    my $dataset = $args{dataset};
    croak "dataset is mandatory" if not defined $dataset;
    if(ref($dataset) ne "ARRAY") {
        $dataset = [$dataset];
    }
    croak "at least one dataset is required" if !@$dataset;
    my $output = $args{output};
    my $writer = $args{writer};
    my $async = $args{async};
    my ($gnuplot_process, $terminator_guard);
    if(!defined($writer)) {
        $gnuplot_process = Gnuplot::Builder::Process->new;
        $writer = $gnuplot_process->writer;
        $terminator_guard = $gnuplot_process->terminator_guard; ## stop the process if aborted.
    }
    
    $writer->($self->to_string);
    if(defined $output) {
        $writer->("set output " . quote_gnuplot_str($output) . "\n");
    }
    my ($params, $dataset_objects) = _collect_dataset_params($dataset);
    $writer->("$plot_command " . join(",", @$params) . "\n");
    _write_inline_data($writer, $dataset_objects);
    if(defined $output) {
        $writer->("set output\n");
    }

    my $result = "";
    if(defined $gnuplot_process) {
        $gnuplot_process->close_input();
        if(!$async) {
            $gnuplot_process->wait_to_finish();
            $result = $gnuplot_process->result;
        }
    }
    $terminator_guard->cancel if defined $terminator_guard;
    return $result;
}

sub plot_with {
    my ($self, %args) = @_;
    return $self->_draw_with(%args, command => "plot");
}

sub splot_with {
    my ($self, %args) = @_;
    return $self->_draw_with(%args, command => "splot");
}

sub plot {
    my ($self, @dataset) = @_;
    return $self->_draw_with(command => "plot", dataset => \@dataset);
}

sub splot {
    my ($self, @dataset) = @_;
    return $self->_draw_with(command => "splot", dataset => \@dataset);
}

1;

__END__

=pod

=head1 NAME

Gnuplot::Builder::Script - object-oriented builder for gnuplot script

=head1 SYNOPSIS

    use Gnuplot::Builder::Script;
    
    my $builder = Gnuplot::Builder::Script->new(<<EOT);
    terminal = png size 500,500 enhanced
    grid     = x y
    xrange   = [-10:10]
    yrange   = [-1:1]
    xlabel   = x offset 0,1
    ylabel   = y offset 1,0
    output   = "sin_wave.png"
    -key
    EOT
    
    $builder->define('f(x) = sin(pi * x)');
    $builder->plot("f(x)");                 ## output sin_wave.png
    
    my $child = $builder->new_child;
    $child->define('f(x) = cos(pi * x)');   ## override parent's setting
    $child->set('output = "cos_wave.png"'); ## override parent's setting
    $child->plot("f(x)");                   ## output cos_wave.png


=head1 DESCRIPTION

L<Gnuplot::Builder::Script> is a builder object for a gnuplot script.

The advantages of this module over just printing script text are:

=over

=item *

It keeps option settings and definitions in a hash-like data structure.
So you can change those items individually.

=item *

It accepts code-refs for script sentences, option settings and definitions.
They are evaluated lazily every time it builds the script.

=item *

It supports prototype-based inheritance similar to JavaScript objects.
A child builder can override its parent's settings.

=back

=head1 CLASS METHODS

=head2 $builder = Gnuplot::Builder::Script->new(@set_args)

The constructor.

The argument C<@set_args> is optional. If it's absent, it creates an empty builder.
If it's set, C<@set_args> is directly given to C<set()> method.

=head1 OBJECT METHODS - BASICS

Most object methods return the object itself, so that you can chain those methods.

=head2 $script = $builder->to_string()

Build and return the gnuplot script string.


=head2 $builder = $buider->add($sentence, ...)

Add gnuplot script sentences to the C<$builder>.

This is a low-level method. B<< In most cases you should use C<set()> and C<define()> methods below. >>

C<$sentences> is a string or a code-ref.
A code-ref is evaluated in list context when it builds the script.
The returned list of strings are added to the script.

You can pass more than one C<$sentence>s.

    $builder->add(<<'EOT');
    set title "sample"
    set xlabel "iteration"
    EOT
    my $unit = "sec";
    $builder->add(sub { qq{set ylabel "Time [$unit]"} });

=head1 OBJECT METHODS - GNUPLOT OPTIONS

Methods to manipulate gnuplot options (the "set" and "unset" commands).

=head2 $builder = $builder->set($opt_name => $opt_value, ...)

Set a gnuplot option named C<$opt_name> to C<$opt_value>.
You can set more than one name-value pairs.

C<$opt_value> is either C<undef>, a string, an array-ref of strings or a code-ref.

=over

=item *

If C<$opt_value> is C<undef>, the "unset" command is generated for the option.

=item *

If C<$opt_value> is a string, the option is set to that string.

=item *

If C<$opt_value> is an array-ref, the "set" command is repeated for each element in it.
If the array is empty, no "set" or "unset" command is generated.

    $builder->set(
        terminal => 'png size 200,200',
        key      => undef,
    );
    $builder->to_string();
    ## => set terminal png size 200,200
    ## => unset key
        
    $builder->set(
        arrow => ['1 from 0,0 to 0,1', '2 from 100,0 to 0,100']
    );
    $builder->to_string();
    ## => set terminal png size 200,200
    ## => unset key
    ## => set arrow 1 0,0 to 0,1
    ## => set arrow 2 from 100,0 to 0,100

=item *

If C<$opt_value> is a code-ref,
it is evaluated in list context when the C<$builder> builds the script.

    @returned_values = $opt_value->($builder, $opt_name)

The C<$builder> and C<$opt_name> are given to the code-ref.

Then, the option is generated as if C<< $opt_name => \@returned_values >> was set.
You can return single C<undef> to "unset" the option.

    my %SCALE_LABEL = (1 => "", 1000 => "k", 1000000 => "M");
    my $scale = 1000;
    $builder->set(
        xlabel => sub { qq{"Traffic [$SCALE_LABEL{$scale}bps]"} },
    );

=back

The options are stored in the C<$builder>'s hash-like structure,
so you can change those options individually.

Even if the options are changed later, their order in the script is unchanged.

    $builder->set(
        terminal => 'png size 500,500',
        xrange => '[100:200]',
        output => '"foo.png"',
    );
    $builder->to_string();
    ## => set terminal png size 500,500
    ## => set xrange [100:200]
    ## => set output "foo.png"
    
    $builder->set(
        terminal => 'postscript eps size 5.0,5.0',
        output => '"foo.eps"'
    );
    $builder->to_string();
    ## => set terminal postscript eps size 5.0,5.0
    ## => set xrange [100:200]
    ## => set output "foo.eps"

Note that you are free to use any string as C<$opt_name>.
In fact, there may be more than one way to build the same script.

    $builder1->set(
        'style data' => 'lines',
        'style fill' => 'solid 0.5'
    );
    $builder2->set(
        style => ['data lines', 'fill solid 0.5']
    );

In the above example, C<$builder1> and C<$builder2> generate the same script.
However, C<$builder2> cannot change the style for "data" or "fill" individually, while C<$builder1> can.


=head2 $builder = $builder->set($options)

If C<set()> method is called with a single string argument C<$options>,
it is parsed to set options.

    $builder->set(<<'EOT');
    xrange = [-5:10]
    output = "foo.png"
    grid
    -key
    
    ## terminal = png size 100,200
    terminal = pngcairo size 400,800
    
    tics = mirror in \
           rotate autojustify
    
    arrow = 1 from 0,10 to 10,0
    arrow = 2 from 5,5  to 10,10
    EOT

Here is the parsing rule:

=over

=item *

Each line is a "set" or "unset" command.

=item *

A "set" line is a pair of option name and value with "=" between them.

    OPT_NAME = OPT_VALUE

=item *

An "unset" line is the option name with leading "-".

    -OPT_NAME

=item *

White spaces around OPT_NAME and OPT_VALUE are ignored.

=item *

If OPT_VALUE is an empty string in "set" line, you can omit "=".

=item *

Lines with a trailing backslash continue to the next line.
The effect is as if the backslash and newline were not there.

=item *

Empty lines are ignored.

=item *

Lines starting with "#" are ignored.

=item *

You can write more than one lines for the same OPT_NAME.
It's the same effect as C<< set($opt_name => [$opt_value1, $opt_value2, ...]) >>.

=back

=head2 $builder = $builder->set_option(...)

C<set_option()> is alias of C<set()>.

=head2 $builder = $builder->setq(...)

C<setq()> method is the same as C<set()> except that eventual option values are quoted.

This method is useful for setting "title", "xlabel", "output" etc.

    $builder->setq(
        output => "hoge.png",
        title  => "hoge's values",
    );
    $builder->to_string;
    ## => set output 'hoge.png'
    ## => set title 'hoge''s values'

If the option value is a list, it quotes the all elements.

=head2 $builder = $builder->setq_option(...)

C<setq_option()> is alias of C<setq()>.


=head2 $builder = $builder->unset($opt_name, ...)

Short-cut for C<< set($opt_name => undef) >>.
It generates "unset" command for the option.

You can specify more that one C<$opt_name>s.

=head2 @opt_values = $builder->get_option($opt_name)

Get the option values for C<$opt_name>.

If C<$opt_name> is set in the C<$builder>, it returns its values.
If a code-ref is set to the C<$opt_name>, it is evaluated and its results are returned.

If C<$opt_name> is not set in the C<$builder>, the values of C<$builder>'s parent are returned.
If C<$builder> does not have parent, it returns an empty list.

Always receive the result of this method by an array, because it may return both C<< (undef) >> and C<< () >>.
Returning an C<undef> means the option is "unset" explicitly,
while returning an empty list means no "set" or "unset" sentence for the option.


=head2 $builder = $builder->delete_option($opt_name, ...)

Delete the values for C<$opt_name> from the C<$builder>.
You can specify more than one C<$opt_name>s.

After C<$opt_name> is deleted, C<get_option($opt_name)> will search the C<$builder>'s parent for the values.

Note the difference between C<delete_option()> and C<unset()>.
While C<unset($opt_name)> will generate "unset" sentence for the option,
C<delete_option($opt_name)> will be likely to generate no sentence (well, strictly speaking, it depends on the parent).

C<delete_option($opt_name)> and C<< set($opt_name => []) >> are also different if the C<$builder> is a child.
C<set()> always overrides the parent setting, while C<delete_option()> resets such overrides.


=head1 OBJECT METHODS - GNUPLOT DEFINITIONS

Methods to manipulate user-defined variables and functions.

Most methods in this category are analogous to the methods in L</OBJECT METHODS - GNUPLOT OPTIONS>.

    +---------------+-------------------+
    |    Options    |    Definitions    |
    +===============+===================+
    | set           | define            |
    | set_option    | set_definition    |
    | setq          | (N/A)             |
    | setq_option   | (N/A)             |
    | unset         | undefine          |
    | get_option    | get_definition    |
    | delete_option | delete_definition |
    +---------------+-------------------+

I'm sure you can understand this analogy by this example.

    $builder->set(
        xtics => 10,
        key   => undef
    );
    $builder->define(
        a      => 100,
        'f(x)' => 'sin(a * x)',
        b      => undef
    );
    $builder->to_string();
    ## => set xtics 10
    ## => unset key
    ## => a = 100
    ## => f(x) = sin(a * x)
    ## => undefine b

=head2 $builder = $builder->define($def_name => $def_value, ...)

=head2 $builder = $builder->define($definitions)

Set function and variable definitions. See C<set()> method.

=head2 $builder = $builder->set_definition(...)

Alias for C<define()> method.

=head2 $builder = $builder->undefine($def_name, ...)

Short-cut for C<< define($def_name => undef) >>. See C<unset()> method.

=head2 @def_values = $builder->get_definition($def_name)

Get definitions from the C<$builder>. See C<get_option()> method.

=head2 $builder = $builder->delete_definition($def_name, ...)

Delete definitions from the C<$builder>. See C<delete_option()> method.

=head1 OBJECT METHODS - PLOTTING

Methods for plotting.

All plotting methods are non-mutator, that is, they don't change the state of the C<$builder>.
This means you can plot different datasets with the same settings.

Some plotting methods run a gnuplot process background, and let it do the plotting work.
The variable C<@Gnuplot::Builder::Process::COMMAND> is used to start the gnuplot process.
See L<Gnuplot::Builder::Process> for detail.

=head2 $result = $builder->plot($dataset, ...)

Build the script and plot the given C<$dataset>s with gnuplot's "plot" command.
This method lets a gnuplot process do the actual job.

You can specify more than one C<$dataset>s to plot.

The return value C<$result> is the data that the gnuplot process writes to STDOUT and STDERR.

Usually you should use a L<Gnuplot::Builder::Dataset> object for C<$dataset>.
In this case, you can skip the rest of this section.

In detail, C<$dataset> is either a string or an object.

=over

=item *

If C<$dataset> is a string, it's treated as the dataset parameters for "plot" command.

    $builder->plot(
        'sin(x) with lines lw 2',
        'cos(x) with lines lw 5',
        '"datafile.dat" using 1:3 with points ps 4'
    );

=item *

If C<$dataset> is an object, it must implement C<params_string()> and C<write_data_to()> methods (like L<Gnuplot::Builder::Dataset>).

C<params_string()> method is supposed to return a string of the dataset parameters,
and C<write_data_to()> method provide the inline data if it has.

The two methods are called like

    ($params_str) = $dataset->params_string();
    $dataset->write_data_to($writer);

where C<$writer> is a code-ref that you must call with the inline data you have.

    package My::Data;
    
    sub new {
        my ($class, $x_data, $y_data) = @_;
        return bless { x => $x_data, y => $y_data }, $class;
    }
    
    sub params_string { q{"-" using 1:2 title "My Data" with lp} }
    
    sub write_data_to {
        my ($self, $writer) = @_;
        foreach my $i (0 .. $#{$self->{x}}) {
            my ($x, $y) = ($self->{x}[$i], $self->{y}[$i]);
            $writer->("$x $y\n");
        }
    }
    
    $builder->plot(My::Data->new([1,2,3], [1,4,9]));


If C<write_data_to()> method doesn't pass any data to the C<$writer>,
the C<plot()> method doesn't generate the inline data section.


=back

=head2 $result = $builder->plot_with(%args)

Plot with more functionalities than C<plot()> method.

Fields in C<%args> are

=over

=item C<dataset> => DATASETS (mandatory)

Datasets to plot. It is either a dataset or an array-ref of datasets.
See C<plot()> for specification of datasets.

=item C<output> => OUTPUT_FILENAME (optional)

If set, "set output" command is printed just before "plot" command,
so that it would output the plot to the specified file.
The specified file name is quoted.
After "plot" command, it prints "set output" command with no argument to unlock the file.

If not set, it won't print "set output" commands.

=item C<writer> => CODE-REF (optional)

A code-ref to receive the whole script string.
If set, it is called one or more times with the script string that C<$builder> builds.
In this case, the return value C<$result> will be an empty string.

If not set, C<$builder> streams the script into the gnuplot process.
The return value C<$result> will be the data the gnuplot process writes to STDOUT and STDERR.

=item C<async> => BOOL (optional, default: false)

If set to true, it won't wait for the gnuplot process to finish.
In this case, the return value C<$result> will be an empty string.

Using C<async> option, you can run more than one gnuplot processes to do the job.
However, the maximum number of gnuplot processes are limited to
the variable C<$Gnuplot::Builder::Process::MAX_PROCESSES>.
See L<Gnuplot::Builder::Process> for detail.

If set to false, which is the default, it waits for the gnuplot process to finish
and return its output.

=back

    my $script = "";
    $builder->plot_with(
        dataset => ['sin(x)', 'cos(x)'],
        output  => "hoge.eps",
        writer  => sub {
            my ($script_part) = @_;
            $script .= $script_part;
        }
    );
    
    $script;
    ## => set output 'hoge.eps'
    ## => plot sin(x),cos(x)
    ## => set output


=head2 $result = $builder->splot($dataset, ...)

Same as C<plot()> method except it uses "splot" command.

=head2 $result = $builder->splot_with(%args)

Same as C<plot_with()> method except it uses "splot" command.


=head1 OBJECT METHODS - INHERITANCE

A L<Gnuplot::Builder::Script> object can extend and/or override another
L<Gnuplot::Builder::Script> object.
This is similar to JavaScript's prototype-based inheritance.

Let C<$parent> and C<$child> be the parent and its child builder, respectively.
Then C<$child> builds a script on top of what C<$parent> builds.
That is,

=over

=item *

Sentences added by C<< $child->add() >> method are appended to the C<$parent>'s script.

=item *

Option settings and definitions in C<$child> are appended to the C<$parent>'s script,
if they are not set in C<$parent>.

=item *

Option settings and definitions in C<$child> are substituted in the C<$parent>'s script,
if they are already set in C<$parent>.

=back


=head2 $builder = $builder->set_parent($parent_builder)

Set C<$parent_builder> as the C<$builder>'s parent.

If C<$parent_builder> is C<undef>, C<$builder> doesn't have a parent anymore.

=head2 $parent_builder = $builder->parent()

Return the C<$builder>'s parent. It returns C<undef> if C<$builder> does not have a parent.

=head2 $child_builder = $builder->new_child()

Create and return a new child builder of C<$builder>.

This is a short-cut for C<< Gnuplot::Builder::Script->new->set_parent($builder) >>.


=head1 OVERLOAD

When you evaluate a C<$builder> as a string, it executes C<< $builder->to_string() >>. That is,

    "$builder" eq $builder->to_string;

=head1 SEE ALSO

L<Gnuplot::Builder::Dataset>

=head1 AUTHOR

Toshio Ito, C<< <toshioito at cpan.org> >>

=cut
